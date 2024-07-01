// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract Marketplace is ChainlinkClient {
    address public immutable platform;
    address public immutable supplier;
    address public immutable distributor;
    address public immutable carrier;
    uint256 public escrowAmount;
    bool public isOrderApproved;
    bool public isProductHandedToCarrier;
    bool public isCarrierConfirmedReceipt;
    bool public isProductDelivered;
    bool public isDistributorConfirmedReceipt;
    uint256 public externalData;
    address private immutable oracle;
    bytes32 private immutable jobId;
    uint256 private immutable fee;

    event Log(string message);
    event LogAddress(string message, address addr);
    event LogBool(string message, bool value);
    event LogUint(string message, uint value);
    event DataFulfilled(bytes32 indexed requestId, uint256 indexed externalData);

    constructor(
        address _supplier, 
        address _distributor, 
        address _carrier, 
        address _oracle, 
        bytes32 _jobId, 
        uint256 _fee
    ) {
        platform = msg.sender;
        supplier = _supplier;
        distributor = _distributor;
        carrier = _carrier;
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
        setChainlinkToken("0x514910771AF9Ca656af840dff83E8264EcF986CA");
        setChainlinkOracle(_oracle);

        emit Log("Constructor called");
        emit LogAddress("Platform", platform);
        emit LogAddress("Supplier", supplier);
        emit LogAddress("Distributor", distributor);
        emit LogAddress("Carrier", carrier);
    }

    modifier onlyPlatform() {
        require(msg.sender == platform, "Only platform can call this function");
        _;
    }

    modifier onlySupplier() {
        require(msg.sender == supplier, "Only supplier can call this function");
        _;
    }

    modifier onlyDistributor() {
        require(msg.sender == distributor, "Only distributor can call this function");
        _;
    }

    modifier onlyCarrier() {
        require(msg.sender == carrier, "Only carrier can call this function");
        _;
    }

    function approveOrder() external onlySupplier {
        isOrderApproved = true;
        emit Log("Order approved");
    }

    function deposit() external payable onlyDistributor {
        require(isOrderApproved, "Order not approved by supplier");
        require(msg.value > 0, "Must deposit funds");
        escrowAmount += msg.value;
        emit LogUint("Funds deposited", msg.value);

        // Fund the contract with LINK tokens
        IERC20("0x514910771AF9Ca656af840dff83E8264EcF986CA").transferFrom(msg.sender, address(this), fee);
    }

    function confirmProductHandoverToCarrier() external onlySupplier {
        isProductHandedToCarrier = true;
        emit Log("Product handed to carrier");
    }

    function confirmCarrierReceipt() external onlyCarrier {
        require(isProductHandedToCarrier, "Product not handed to carrier by supplier");
        isCarrierConfirmedReceipt = true;
        emit Log("Carrier confirmed receipt");
    }

    function confirmProductDelivery() external onlyCarrier {
        require(isCarrierConfirmedReceipt, "Carrier has not confirmed receipt of the product");
        isProductDelivered = true;
        emit Log("Product delivered by carrier");
    }

    function confirmDistributorReceipt() external onlyDistributor {
        require(isProductDelivered, "Product not delivered by carrier");
        isDistributorConfirmedReceipt = true;
        requestExternalData();
        emit Log("Distributor confirmed receipt");
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
        releaseFunds();
    }

    function releaseFunds() internal {
        require(isDistributorConfirmedReceipt, "Distributor has not confirmed receipt");
        require(escrowAmount > 0, "No funds to release");
        uint256 amountToRelease = escrowAmount;
        escrowAmount = 0;
        payable(supplier).transfer(amountToRelease);
        emit LogUint("Funds released", amountToRelease);
    }
}
