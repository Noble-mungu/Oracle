// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract Escrow is ChainlinkClient {
    address public immutable payer;
    address public immutable payee;
    address public immutable escrowAgent;
    uint256 public immutable amount;
    uint256 public externalData;
    address private immutable oracle;
    bytes32 private immutable jobId;
    uint256 private immutable fee;

    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, REFUNDED }
    State public currentState;

    event PaymentDeposited(address indexed payer, uint256 amount);
    event PaymentReleased(address indexed payee, uint256 amount);
    event PaymentRefunded(address indexed payer, uint256 amount);
    event DataFulfilled(bytes32 indexed requestId, uint256 indexed externalData);

    constructor(
        address _payee, 
        address _escrowAgent, 
        uint256 _amount, 
        address _oracle, 
        bytes32 _jobId, 
        uint256 _fee
    ) {
        payer = msg.sender;
        payee = _payee;
        escrowAgent = _escrowAgent;
        amount = _amount;
        currentState = State.AWAITING_PAYMENT;
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
        setChainlinkToken("0x514910771AF9Ca656af840dff83E8264EcF986CA");
        setChainlinkOracle(_oracle);
    }

    modifier onlyPayer() {
        require(msg.sender == payer, "Only payer can call this method");
        _;
    }

    modifier onlyEscrowAgent() {
        require(msg.sender == escrowAgent, "Only escrow agent can call this method");
        _;
    }

    modifier inState(State expectedState) {
        require(currentState == expectedState, "Invalid state");
        _;
    }

    function depositPayment() external payable onlyPayer inState(State.AWAITING_PAYMENT) {
        require(msg.value == amount, "Incorrect payment amount");
        currentState = State.AWAITING_DELIVERY;
        emit PaymentDeposited(msg.sender, msg.value);

        // Fund the contract with LINK tokens
        IERC20(linkToken()).transferFrom(msg.sender, address(this), fee);
    }

    function confirmDelivery() external onlyEscrowAgent inState(State.AWAITING_DELIVERY) {
        requestExternalData();
    }

    function refundPayment() external onlyEscrowAgent inState(State.AWAITING_DELIVERY) {
        currentState = State.REFUNDED;
        payable(payer).transfer(amount);
        emit PaymentRefunded(payer, amount);
    }

    function requestExternalData() public {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", "https://api.example.com/data"); 
        request.add("path", "data.value"); 
        sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _externalData) public recordChainlinkFulfillment(_requestId) {
        externalData = _externalData;
        emit DataFulfilled(_requestId, _externalData);
        finalizeDelivery();
    }

    function finalizeDelivery() internal {
        currentState = State.COMPLETE;
        payable(payee).transfer(amount);
        emit PaymentReleased(payee, amount);
    }
}
