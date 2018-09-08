pragma solidity ^0.4.24;


contract LogisticEvents {

    // sign contract
    event onSign
    (
        address addr,   // User address
        string name,   // User name
        uint256 idCard, // User Id Card
        uint256 scoreCredit,  // Credit score
        uint256 userType // User type ,1:customer,2:driver
    );

    // create order
    event onCreateOrder
    (
        uint256 id,      // order id
        uint256 eth,    // eth custumer pay total
        uint256 custumerIdCard,   // custumer id card
        address custumerAddr,   // custumer address
        uint256 driverIdCard,   // driver id card
        address driverAddr   // driver address
    );

    event onConfirmOrder(
        uint256 orderId      // order id
    );
}

contract Logistic1 is LogisticEvents{

   // address private admin = msg.sender;
    /** contract total money */
    uint256 public pool = 0;
    /**team 5% when someone win*/
// uint256 public com = 5;

    InsuranceInterface constant private Insurance = InsuranceInterface(0x34ed2237f245d3823348c83aeb2c12895cdf302c);
    ETCInterface constant private ETC = ETCInterface(0x43049c7fb27235971c8953641b4a7ce21553ad6a);

    //****************
    // User DATA
    //****************
    mapping (uint256 => LogisticDatasets.User) public users;          // (idCard => users)  include customer and driver


    //****************
    // Order DATA
    //****************
    mapping (uint256 => LogisticDatasets.Order) public orders;          // (orderId => order)  orders

    //****************
    // Fee DATA
    //****************
    mapping (uint256 => LogisticDatasets.ParticipantFees) public participantFees;          // (orderId => ParticipantFees)  orders


    //****************
    // init DATA
    //****************
    uint256 unitDriverPrice;// unit diver price per km
    uint256 unitEtcPrice;// unit etc price per
    uint256 insurancePercent;// estimate price

    uint256 currentOrderId;// order initial id
    // uint256 insuranceFee;// totalFee - etcTotalPrice - driverFee

     constructor()
        public
    {
        unitDriverPrice = 10 ** 16;// 0.01eth
        insurancePercent = 2; // 2%
        unitEtcPrice = 5 * (10 ** 14);// 0.0005eth

        currentOrderId = 0;// the order id is 0 when the contract started
	}

     /**
     * if customer and driver are all sign contract
     */
    modifier isSign(uint256 _idCard,uint256 _driverIdCard) {
        require(users[_idCard].idCard != 0, "sorry customer must be sign the contract");
        require(users[_driverIdCard].idCard != 0, "sorry driver must be sign the contract");
        _;
    }

     modifier onlyCustomer(address _customerAddr,uint256 _orderId){
        require(orders[_orderId].custumerAddr == _customerAddr,"must be confirm by the customer who owned the order");
        _;
     }


    function put() public payable{
        pool=pool + msg.value;
    }

    /** customer pay total*/
    function corePay(uint256 _distance,uint256 _idCard,uint256 _driverIdCard,string _goods,uint256 _estimatePrice)
    isSign(_idCard,_driverIdCard)
    public payable{

        pool = pool + msg.value;
        currentOrderId = currentOrderId +1;
        address driverAddr = users[_driverIdCard].addr;
        orders[currentOrderId] = LogisticDatasets.Order(currentOrderId,msg.value,_idCard,msg.sender,_driverIdCard,driverAddr,_distance,_goods,"");

        emit LogisticEvents.onCreateOrder(currentOrderId,msg.value,_idCard,msg.sender,_driverIdCard,driverAddr);

        participantFees[currentOrderId] = LogisticDatasets.ParticipantFees(_distance * unitEtcPrice,_distance * unitDriverPrice,_estimatePrice * insurancePercent / 100);

        uint256 balance = msg.value - participantFees[currentOrderId].etcFee - participantFees[currentOrderId].driverFee - participantFees[currentOrderId].insuranceFee;
        require(balance >= 0,"balance must be greater than 0");
        if(balance > 0){
            msg.sender.transfer(balance);
        }

        Insurance.core.value(participantFees[currentOrderId].insuranceFee)(currentOrderId,_idCard,msg.sender,_distance,_goods,_estimatePrice);
        ETC.core.value(participantFees[currentOrderId].etcFee)(currentOrderId);
        pool = pool - participantFees[currentOrderId].insuranceFee - participantFees[currentOrderId].etcFee;

    }

    function confirm(uint256 _orderId) 
    onlyCustomer(msg.sender,_orderId)
    public payable{
        address driverAddr = orders[_orderId].driverAddr;
        uint256 driverFee = participantFees[_orderId].driverFee;
        driverAddr.transfer(driverFee);
        pool = pool - driverFee;
        emit LogisticEvents.onConfirmOrder(_orderId);
      //  ETC.confirm(_orderId);

        users[orders[_orderId].driverIdCard].scoreCredit++;
    }

    function sign(string name, uint256 idCard,uint256 userType) public{

        require(idCard>0,"customer id card must be greater than 0");

        users[idCard]=LogisticDatasets.User(msg.sender,name,idCard,100,userType);
        emit LogisticEvents.onSign(msg.sender,name,idCard,100,userType);

    }


}

interface InsuranceInterface {
    function core(uint256 logisticOrderId,uint256 customerIdCard,address customerAddr,uint256 distance,string goods,uint256 estimatePrice)  external payable;
}
interface ETCInterface {
    function core(uint256 logisticOrderId)  external payable;
    function confirm(uint256 logisticOrderId) external;
}


//==============================================================================
//  Logistic Datasets
//==============================================================================
library LogisticDatasets {

    struct User {
        address addr;   // User address
        string name;   // User name
        uint256 idCard; // User Id Card
        uint256 scoreCredit;  // Credit score
        uint256 userType; // User type ,1:customer,2:driver
    }
    struct Order {
        uint256 id;      // order id
        uint256 eth;    // eth custumer pay total
        uint256 custumerIdCard;   // custumer id card
        address custumerAddr;   // custumer address
        uint256 driverIdCard;   // driver id card
        address driverAddr;   // driver address
        uint256 distance;       // distance
        string goods;     // goods
        string extra;    // extra infomation
    }

    struct ParticipantFees{
        uint256 etcFee;   //etc estimate fee
        uint256 driverFee;  //driver receive fee
        uint256 insuranceFee; //insurance fee
    }
}
