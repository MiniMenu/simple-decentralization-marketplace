// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralisedMarketPlace{
    error DecentralisedMarketPlace__ItemUnAvailable();
    error DecentralisedMarketPlace__ItemStillAvailable();
    error DecentralisedMarketPlace__InvalidItemNumber();
    error DecentralisedMarketPlace__IncorrectPrice();
    error DecentralisedMarketPlace__CannotCancelWithoutACompleteOrder();

    struct Item {
        string itemName;
        string itemDescription;
        uint256 price;
        address seller;
        bool availabilityStatus;
    }

    event ItemAdded(string itemName, uint256 price, address seller, bool availability);
    event OrderPlacedByCustomer(uint256 itemId, address buyer, uint256 price);
    event TransactionComplete(uint256 itemId, address buyer, address seller, uint256 price);
    event OrderCancellationPlacedByCustomer(uint256 itemId, address buyer, uint256 price);
    event CancelationCompleted(uint256 itemId, uint256 price);

    mapping(uint256 => Item) private items;
    uint256 private itemId;
    address immutable private seller;
    mapping(uint256 => address) private orders;
    
    constructor() {
        seller = msg.sender;
    }

    modifier onlySeller {
        require( seller == msg.sender, "You are not a seller");
        _;
    }

    modifier onlyBuyer {
        require( seller != msg.sender, "You are not a buyer");
        _;
    }

    function insertItems(string memory _name, string memory _description, uint256 _price) public onlySeller{
        itemId++;
        items[itemId] = Item(_name, _description, _price, payable(msg.sender), true);
        emit ItemAdded(items[itemId].itemName, items[itemId].price, items[itemId].seller, items[itemId].availabilityStatus);
    }

    function placeAnOrder(uint256 _itemId) public payable onlyBuyer{
        if (_itemId  < 0 && _itemId > itemId) {
            revert DecentralisedMarketPlace__InvalidItemNumber();
        }

        Item memory selectedItem = items[_itemId];

        if (selectedItem.availabilityStatus == false) {
            revert DecentralisedMarketPlace__ItemUnAvailable();
        }

        if (msg.value == selectedItem.price) {
            revert DecentralisedMarketPlace__IncorrectPrice();
        }

        items[_itemId].availabilityStatus = false;
        emit OrderPlacedByCustomer(_itemId, msg.sender, msg.value);   
    }


    function completeTransaction(uint256 _itemId) public onlyBuyer {
        if (itemId  < 0 && _itemId > itemId) {
            revert DecentralisedMarketPlace__InvalidItemNumber();
        }
        if (items[_itemId].availabilityStatus == true) {
            revert DecentralisedMarketPlace__ItemStillAvailable();
        }
    
        payable(items[_itemId].seller).transfer(items[_itemId].price * 1e18);

        emit TransactionComplete(_itemId, msg.sender, items[_itemId].seller, (items[_itemId].price * 1e18));
        orders[_itemId] = msg.sender;
    }


    function cancelOrder(uint256 _itemId) public onlyBuyer{
        if (itemId < 0 && _itemId > itemId) {
            revert DecentralisedMarketPlace__InvalidItemNumber();
        }
        if (items[_itemId].availabilityStatus == true) {
            revert DecentralisedMarketPlace__ItemStillAvailable();
        }
        if (orders[_itemId] != msg.sender){
            revert DecentralisedMarketPlace__CannotCancelWithoutACompleteOrder();
        }

        emit OrderCancellationPlacedByCustomer(_itemId, items[_itemId].seller, items[_itemId].price);
    }

    function processCancellation(uint256 _itemId) public payable onlySeller {
         if (itemId < 0 && _itemId > itemId) {
            revert DecentralisedMarketPlace__InvalidItemNumber();
        }
        if (msg.value == items[_itemId].price) {
            revert DecentralisedMarketPlace__IncorrectPrice();
        }

        items[_itemId].availabilityStatus = true;
        _refundMoney(orders[_itemId], items[_itemId].price);
        emit CancelationCompleted(_itemId, items[_itemId].price);
        delete orders[_itemId];
    }

    function _refundMoney(address buyer, uint256 price) private onlySeller{
        payable(buyer).transfer(price * 1e18);
    }

    function getItem(uint256 _itemId) public view returns(string memory itemDetails, uint256 price, bool availableStatus, address sellerAddr){
        if (itemId < 0 && _itemId > itemId) {
            revert DecentralisedMarketPlace__InvalidItemNumber();
        }
        Item storage item = items[_itemId];
        return (item.itemName, item.price, item.availabilityStatus, item.seller);
    }

}

