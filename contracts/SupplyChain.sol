// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error OutOfStock();

contract SupplyChain {
    enum OrderStatus {
        Placed,
        InChain,
        DeliveryConfirmByDP,
        Delivered
    }

    struct Product {
        string name;
        string imgURL;
        uint256 price;
        uint productId;
        uint256 availableQuantity;
        address payable seller;
    }

    struct Order {
        uint256 time;
        uint orderId;
        uint quantity;
        address buyer;
        bool bid; //true when available for bidding false when delivery is assigned to delivery person
        address deliveryPerson;
        uint deliverPrice;
        uint deliveryTime;
        uint orderPrice;
        address payable seller;
        Bidding bidding;
        OrderStatus status;
    }

    struct BuyerDetails {
        string name;
        uint locationPinCode;
        string locationName;
        string contactNumber;
    }

    struct SellerDetails {
        string name;
        uint locationPinCode;
        string locationName;
        string contactNumber;
    }

    struct DeliveryPerson {
        string name;
        string contactNumber;
        string companyName;
        address dpAddress;
        uint employeeID;
    }

    struct Bidder {
        address bidderAddress;
        uint timeBid;
        uint priceBid;
    }

    struct Bidding {
        bool started;
        uint endAt;
    }

    uint productId = 1;
    uint orderId = 1;
    uint empID = 1;

    mapping(uint => Product) public products;
    mapping(address => mapping(uint256 => Order)) public orders;
    mapping(address => uint256) public orderCount;
    mapping(uint => Order) public orderList;
    mapping(address => DeliveryPerson) public deliveryPersons;
    mapping(address => BuyerDetails) public buyers;
    mapping(address => SellerDetails) public sellers;
    mapping(uint => Bidder) public currentBidder;

    address[] public deliverPersonAddressArray;

    modifier onlySellers() {
        require(sellers[msg.sender].locationPinCode != 0, "Access denied");
        _;
    }

    modifier onlyBuyers() {
        require(buyers[msg.sender].locationPinCode != 0, "Access denied");
        _;
    }

    modifier onlyDeliveryPerson() {
        require(deliveryPersons[msg.sender].employeeID != 0, "Access denied");
        _;
    }

    function signUpForBuyer(
        string memory _name,
        uint _locationPinCode,
        string memory _locationName,
        string memory _contactNumber
    ) public {
        require(_locationPinCode != 0, "Enter valid location");
        require(bytes(_contactNumber).length != 0, "Enter valid valid number");
        BuyerDetails memory BD;
        BD.name = _name;
        BD.locationPinCode = _locationPinCode;
        BD.locationName = _locationName;
        BD.contactNumber = _contactNumber;
        buyers[msg.sender] = BD;
    }

    function signUpForSeller(
        string memory _name,
        uint _locationPinCode,
        string memory _locationName,
        string memory _contactNumber
    ) public {
        require(_locationPinCode != 0, "Enter valid location");
        require(bytes(_contactNumber).length != 0, "Enter valid valid number");
        SellerDetails memory SD;
        SD.name = _name;
        SD.locationPinCode = _locationPinCode;
        SD.locationName = _locationName;
        SD.contactNumber = _contactNumber;
        sellers[msg.sender] = SD;
    }

    function signUpForDeliveryPerson(
        string memory _companyName,
        string memory _contactNumber,
        string memory _name
    ) public {
        require(bytes(_contactNumber).length != 0, "Enter valid location");
        require(bytes(_companyName).length != 0, "Enter valid location");
        require(bytes(_name).length != 0, "Enter valid location");
        DeliveryPerson memory DP;
        DP.companyName = _companyName;
        DP.contactNumber = _contactNumber;
        DP.name = _name;
        DP.dpAddress = msg.sender;
        DP.employeeID = empID;
        deliveryPersons[msg.sender] = DP;
        deliverPersonAddressArray.push(msg.sender);
        empID++;
    }

    function regProduct(
        string memory _name,
        string memory _imgURL,
        uint _price,
        uint _avalQuantity
    ) public onlySellers {
        require(_price != 0, "Price cannot be zero");
        require(_avalQuantity != 0, "Quantity cannot be zero");
        require(bytes(_name).length != 0, "You have add name");

        Product memory tempProduct;

        tempProduct.name = _name;
        tempProduct.imgURL = _imgURL;
        tempProduct.price = _price;
        tempProduct.availableQuantity = _avalQuantity;
        tempProduct.seller = payable(msg.sender);
        tempProduct.productId = productId;

        products[productId] = tempProduct;
        productId++;
    }

    function buyProduct(
        uint _productId,
        uint _quantity
    ) public payable onlyBuyers {
        if (products[_productId].availableQuantity == 0) {
            revert OutOfStock();
        }

        require(
            _quantity <= products[_productId].availableQuantity,
            "Reduce the quantity"
        );
        require(
            msg.value == products[_productId].price * _quantity,
            "Send exact amount"
        );

        Order memory order;

        order.buyer = msg.sender;
        order.time = block.timestamp;
        order.quantity = _quantity;
        order.bid = true;
        order.orderId = orderId;
        order.bidding.started = true;
        order.bidding.endAt = block.timestamp + 60 seconds;
        order.deliveryTime = 10;
        order.deliverPrice = 1e18;
        order.orderPrice = products[_productId].price * _quantity;
        order.seller = products[_productId].seller;
        order.status = OrderStatus.Placed;
        orders[msg.sender][orderId] = order;
        orderList[orderId] = order;
        orderCount[msg.sender]++;
        orderId++;

        products[_productId].availableQuantity -= _quantity;
    }

    function bid(
        uint _orderId,
        uint _amount,
        uint _time
    ) public onlyDeliveryPerson {
        require(
            _amount < currentBidder[_orderId].priceBid &&
                _time < currentBidder[_orderId].timeBid,
            "Your bid is more than current bid"
        );
        require(orderList[_orderId].bidding.started, "Bidding is not started");
        require(block.timestamp < orderList[_orderId].bidding.endAt, "Ended!");
        currentBidder[_orderId].priceBid = _amount;
        currentBidder[_orderId].timeBid = _time;
        currentBidder[_orderId].bidderAddress = msg.sender;
    }

    function stopBidding(uint _orderId) public {
        require(block.timestamp >= orderList[_orderId].bidding.endAt, "Ended!");
        orderList[_orderId].bidding.started = false;
    }

    function addDeliveryDetails(uint _orderId) public onlyDeliveryPerson {
        require(
            !orderList[_orderId].bidding.started,
            "Bidding is still going on"
        );
        orderList[_orderId].deliveryTime = currentBidder[_orderId].timeBid;
        orderList[_orderId].deliverPrice = currentBidder[_orderId].priceBid;
        orderList[_orderId].deliveryPerson = currentBidder[_orderId]
            .bidderAddress;
        orderList[_orderId].bid = false;
    }

    function pickupOrder(uint _orderId) public {
        require(
            orderList[_orderId].deliveryPerson == msg.sender,
            "Access denied"
        );
        require(
            orderList[_orderId].status == OrderStatus.Placed,
            "Order not availbale"
        );
        orderList[_orderId].status = OrderStatus.InChain;
    }

    function confirmDeliveryDP(uint _orderId) public {
        require(
            orderList[_orderId].deliveryPerson == msg.sender,
            "Access denied"
        );
        require(
            orderList[_orderId].status == OrderStatus.InChain,
            "Order is not in chain"
        );
        orderList[_orderId].status = OrderStatus.DeliveryConfirmByDP;
    }

    function confirmDeliveryCustomer(uint _orderId) public payable {
        require(
            msg.value == orderList[_orderId].deliverPrice,
            "Pay the delivery price"
        );
        require(orderList[_orderId].buyer == msg.sender, "Access denied");
        require(
            orderList[_orderId].status == OrderStatus.DeliveryConfirmByDP,
            "Delivery not confirm by DP"
        );
        orderList[_orderId].status = OrderStatus.Delivered;
    }

    function recieveMoney(uint _orderId) public {
        require(
            orderList[_orderId].deliveryPerson == msg.sender,
            "Access denied"
        );
        require(
            orderList[_orderId].status == OrderStatus.Delivered,
            "Delivery not confirmed by buyer"
        );
        payable(orderList[_orderId].seller).transfer(
            orderList[_orderId].orderPrice
        );
        payable(msg.sender).transfer(orderList[_orderId].deliverPrice);
    }
}
