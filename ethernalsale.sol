pragma solidity ^0.4.2;

contract ethernalSale {
    struct order {
        uint amount;
        address buyer;
    }
    
    mapping (uint => order) orderBook;
    mapping (address => uint) balanceOf;
    
    uint public highestPrice;
    uint public totalSold;
    uint public totalTokens;
    uint public minAmount;
    uint public saleStarted;
    address public crowdseller;
    
    
    // Generates an ethernal sale
    function ethernalSale(){
        minAmount = 1 ether / 1000;
        saleStarted = now;
    }
    
    // adds a buy order
    function putOrder(uint price) payable {
        if (msg.value < minAmount) throw;
        // there can be only one order per price point
        // so it looks for a similar price point to add
        bool seekPrice = true;
        uint currPrice = price;
        while(seekPrice) {
            order o = orderBook[currPrice];
            if (o.amount == 0 || currPrice < price - 100) seekPrice = false;
            currPrice--;
        }
        // if still hasn't found, throw
        if (o.amount != 0) throw;
        // create a order
        orderBook[currPrice] = order({amount: msg.value/currPrice, buyer: msg.sender});
        if (currPrice > highestPrice) highestPrice = currPrice;
        
        executeSale();
    }
    
    // cancels an order
    function cancelOrder(uint price) {
        order o = orderBook[price];
        if (o.amount == 0 || o.buyer != msg.sender) throw;
        orderBook[price] = order({amount: 0, buyer: 0});
        msg.sender.transfer(price*o.amount);
    }
    
    // a curve that generates how many tokens per seconds should be generated
    function sellTargetByDate(uint targetTime) constant returns (uint sellTarget) {
       // can be any curve: example targets 1 M tokens per day forever
       return (1000000 * (targetTime - saleStarted)) / 1 days;
    }
    
    // anyone can call this, and it's also called at every put order
    function executeSale() {
        uint targetSale = sellTargetByDate(now) - totalSold;
        uint currPrice = highestPrice;
        while(targetSale > 0) {
            // if it's about to run out of gas, stop it
            if (msg.gas < 1000) targetSale = 0;
            // loop throught the highest sale
            order o = orderBook[currPrice];
            if (o.amount <= targetSale) {
                targetSale -= o.amount;
                totalSold += o.amount;
                crowdseller.transfer(o.amount);
            } else {
                o.amount -= targetSale;
                targetSale = 0;
                totalSold += o.amount;
                crowdseller.transfer(o.amount);
            }
            currPrice--;
        }
        highestPrice = currPrice;
    }
    
    
}