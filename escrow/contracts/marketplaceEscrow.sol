// contracts/Escrow.sol
pragma solidity ^0.8.0;

contract Escrow {
    address public platform;
    address public supplier;
    address public distributor;
    address public carrier;
    uint256 public escrowAmount;
    bool public isOrderApproved;
    bool public isProductHandedToCarrier;
    bool public isCarrierConfirmedReceipt;
    bool public isProductDelivered;
    bool public isDistributorConfirmedReceipt;

    event Log(string message);
    event LogAddress(string message, address addr);
    event LogBool(string message, bool value);
    event LogUint(string message, uint value);

    constructor(address _supplier, address _distributor, address _carrier) {
        platform = msg.sender;
        supplier = _supplier;
        distributor = _distributor;
        carrier = _carrier;

        emit Log("Constructor called");
        emit LogAddress("Platform", platform);
        emit LogAddress("Supplier", supplier);
        emit LogAddress("Distributor", distributor);
        emit LogAddress("Carrier", carrier);
    }

    // Approve order by supplier
    function approveOrder() external onlySupplier {
        isOrderApproved = true;
        emit Log("Order approved");
    }

    // Deposit funds into the escrow by distributor
    function deposit() external payable onlyDistributor {
        require(isOrderApproved, "Order not approved by supplier");
        require(msg.value > 0, "Must deposit funds");
        escrowAmount += msg.value;
        emit LogUint("Funds deposited", msg.value);
    }

    // Confirm product handover to carrier by supplier
    function confirmProductHandoverToCarrier() external onlySupplier {
        isProductHandedToCarrier = true;
        emit Log("Product handed to carrier");
    }

    // Confirm receipt of product by carrier
    function confirmCarrierReceipt() external onlyCarrier {
        require(isProductHandedToCarrier, "Product not handed to carrier by supplier");
        isCarrierConfirmedReceipt = true;
        emit Log("Carrier confirmed receipt");
    }

    // Confirm product delivery by carrier
    function confirmProductDelivery() external onlyCarrier {
        require(isCarrierConfirmedReceipt, "Carrier has not confirmed receipt of the product");
        isProductDelivered = true;
        emit Log("Product delivered by carrier");
    }

    // Confirm receipt of product by distributor
    function confirmDistributorReceipt() external onlyDistributor {
        require(isProductDelivered, "Product not delivered by carrier");
        isDistributorConfirmedReceipt = true;
        releaseFunds();
        emit Log("Distributor confirmed receipt");
    }

    // Release funds to the supplier upon confirmation of delivery and receipt
    function releaseFunds() internal {
        require(isDistributorConfirmedReceipt, "Distributor has not confirmed receipt");
        require(escrowAmount > 0, "No funds to release");
        payable(supplier).transfer(escrowAmount);
        escrowAmount = 0;
        emit LogUint("Funds released", escrowAmount);
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
}
