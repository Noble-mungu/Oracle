// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public payer;
    address public payee;
    address public escrowAgent;
    uint256 public amount;

    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, REFUNDED }
    State public currentState;

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

    event PaymentDeposited(address indexed payer, uint256 amount);
    event PaymentReleased(address indexed payee, uint256 amount);
    event PaymentRefunded(address indexed payer, uint256 amount);

    constructor(address _payee, address _escrowAgent, uint256 _amount) {
        payer = msg.sender;
        payee = _payee;
        escrowAgent = _escrowAgent;
        amount = _amount;
        currentState = State.AWAITING_PAYMENT;
    }

    function depositPayment() external payable onlyPayer inState(State.AWAITING_PAYMENT) {
        require(msg.value == amount, "Incorrect payment amount");
        currentState = State.AWAITING_DELIVERY;
        emit PaymentDeposited(msg.sender, msg.value);
    }

    function confirmDelivery() external onlyEscrowAgent inState(State.AWAITING_DELIVERY) {
        currentState = State.COMPLETE;
        payable(payee).transfer(amount);
        emit PaymentReleased(payee, amount);
    }

    function refundPayment() external onlyEscrowAgent inState(State.AWAITING_DELIVERY) {
        currentState = State.REFUNDED;
        payable(payer).transfer(amount);
        emit PaymentRefunded(payer, amount);
    }
}