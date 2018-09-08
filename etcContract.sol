contract ETCContract{

     /** contract total money */
    uint256 public pool = 0;
    address private etcAddr = 0x87cfbf13a4de9448339642c8608901ccc99b0e23;

    //****************
    // ETC Order
    //****************
    mapping (uint256 => EtcOrder) public EtcOrders;          // (customerIdCard => etcOrder)  etcOrders

    function core(uint256 logisticOrderId) public payable{
        pool = pool + msg.value;
        EtcOrders[logisticOrderId] = EtcOrder(msg.sender,msg.value);
    }

    function reduce(uint256 logisticOrderId) public payable{
        EtcOrders[logisticOrderId].eth = EtcOrders[logisticOrderId].eth - 10 ** 17;
        etcAddr.transfer(10 ** 17);
    }

    function confirm(uint256 logisticOrderId) public{
        if (EtcOrders[logisticOrderId].eth > 0) {
            pool = pool - EtcOrders[logisticOrderId].eth;
            msg.sender.transfer(EtcOrders[logisticOrderId].eth);
        }
    }

    struct EtcOrder{
        address customerAddr;       //customer address
        uint256 eth;                // eth custumer pay total
    }
}
