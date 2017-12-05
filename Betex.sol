pragma solidity ^ 0.4 .13;

import "./Oracled.sol";
import "./BetexToken.sol";
import './SafeMath.sol';
import './Commission.sol';

contract Betex is Oracled {
    using SafeMath for uint;

    enum BidType {
        NON,
        CALL,
        PUT,
        NO_CHANGES
    }

    address tokenContractAddress;

    // closed by not finished baskets
    mapping(uint32 => uint32) frozenKeys;

    address commissionAddress;

    uint commissionProcent;

    mapping(uint32 => Bid[]) bids;
    mapping(uint32 => Basket) baskets;

    BetexToken tokenContract;
    Commission commissionContract;

    struct Bid {
        address bidderAddress;
        uint value;
        BidType bidType;
        bool isRewarded;
    }

    struct Basket {
        uint32 key;
        uint bidCallTotal;
        uint bidPutTotal;
        uint32 putAmount; // amount of user which have bid type: put
        uint32 callAmount; // amount of user which have bid type: put
        uint rewarded;
        BidType bidType;
    }

    event BidUser(address user, uint val, uint32 bidType, uint32 key, uint timestamp);

    event RewardUser(address user, uint val, uint winValue, uint32 bidType, uint32 key, uint timestamp);

    event BasketChangeState(uint32 key, uint callTokens, uint putTokens, uint32 callAmount, uint32 putAmount, uint32 bidType);

    function Betex(address _tokenContractAddress) public {
        tokenContractAddress = _tokenContractAddress;
        tokenContract = BetexToken(tokenContractAddress);
        commissionProcent = 1;
    }

    modifier onlyUnfrozen(uint32 key) {
        if (frozenKeys[key] == 0x0)
            _;
    }

    function bidUser(uint _value, uint32 _bidType, uint32 _key) external onlyUnfrozen(_key) {
        require(_bidType == 1 || _bidType == 2);
        require(_value > 0);
        require(tokenContract.balanceOf(msg.sender) >= _value);

        BidType inBidType = BidType(_bidType);
        //transfer user tokens to contract
        tokenContract.transferToBetex(msg.sender, _value);

        //put user in list
        bids[_key].push(Bid(msg.sender, _value, inBidType, false));

        //add user tokens to basket
        Basket storage basket = baskets[_key];
        if (basket.key != _key) {
            baskets[_key] = Basket(_key, 0, 0, 0, 0, 0, BidType.NON);
        }

        if (inBidType == BidType.CALL) {
            basket.bidCallTotal += _value;
            basket.callAmount = basket.callAmount + 1;
        } else {
            basket.bidPutTotal += _value;
            basket.putAmount = basket.putAmount + 1;
        }

        BidUser(msg.sender, _value, uint32(inBidType), _key, block.timestamp);
        BasketChangeState(basket.key, basket.bidCallTotal, basket.bidPutTotal, basket.callAmount, basket.putAmount, uint32(basket.bidType));
    }

    function closeBasket(uint32 _key) external onlyOracle() {
        frozenKeys[_key] = _key;
    }

    function getBidsAmount(uint32 _key) public view returns(uint256) {
        Bid[] storage bidsByKey = bids[_key];

        return bidsByKey.length;
    }

    function reward(uint32 _from, uint32 _to, uint32 _bidType, uint32 _key) external onlyOracle() {
        require(_bidType == 1 || _bidType == 2 || _bidType == 3);
        if (_from == _to)
            return;
        //Get busket and init type
        Basket storage basket = baskets[_key];
        require(basket.key == _key);
        basket.bidType = BidType(_bidType);

        Bid[] storage bidsByKey = bids[_key];

        uint totalBid = basket.bidCallTotal + basket.bidPutTotal;
        uint totalTokensOfWinners;
        uint totalTokensOfLosers;
        if (basket.bidType == BidType.CALL) {
            totalTokensOfWinners = basket.bidCallTotal;
            totalTokensOfLosers = basket.bidPutTotal;
        } else if (basket.bidType == BidType.PUT) {
            totalTokensOfWinners = basket.bidPutTotal;
            totalTokensOfLosers = basket.bidCallTotal;
        }


        for (uint32 i = _from; i < _to; i++) {
            Bid storage currBid = bidsByKey[i];

            if (basket.bidType == BidType.NO_CHANGES || totalTokensOfLosers == 0) {

                if (basket.rewarded + currBid.value <= totalBid && !currBid.isRewarded) {
                    //reward user
                    tokenContract.transferFromBetex(currBid.bidderAddress, currBid.value);
                    currBid.isRewarded = true;
                    //change basket state
                    basket.rewarded += currBid.value;
                    RewardUser(currBid.bidderAddress, currBid.value, currBid.value, uint32(currBid.bidType), basket.key, block.timestamp);
                }
            } else if (currBid.bidType == basket.bidType && !currBid.isRewarded) {
                //сount amount of tokens that user will get
                uint percent = currBid.value.mul(1000000).div(totalTokensOfWinners);
                uint rewardd = totalBid.mul(percent).div(1000000);
                //count commision from the profit
                uint commission = commissionProcent.mul(rewardd).div(100);
                //transfer reward from basket to user
                if (basket.rewarded + rewardd <= totalBid) {
                    //reward user
                    tokenContract.transferFromBetex(currBid.bidderAddress, rewardd.sub(commission));
                    //get comission from user profit
                    tokenContract.transferFromBetex(commissionAddress, commission);
                    commissionContract.received(currBid.bidderAddress, commission);

                    currBid.isRewarded = true;
                    //change basket state
                    basket.rewarded += rewardd;
                    RewardUser(currBid.bidderAddress, currBid.value, rewardd.sub(commission), uint32(currBid.bidType), basket.key, block.timestamp);
                }
            } else {
                RewardUser(currBid.bidderAddress, currBid.value, 0, uint32(currBid.bidType), basket.key, block.timestamp);
            }
        }
    }

    function finishBasket(uint32 _key) external onlyOracle() {
        delete frozenKeys[_key];
        delete bids[_key];
        delete baskets[_key];
    }

    function setCommissionAddress(address _commissionAddress) public onlyContractOwner() {
        require(_commissionAddress != tokenContract.getOwner());
        commissionContract = Commission(_commissionAddress);
        commissionAddress = _commissionAddress;
    }

    function setCommissionProcent(uint _percent) public onlyContractOwner() {
        require(_percent > 0 && _percent < 100);
        commissionProcent = _percent;
    }

}
