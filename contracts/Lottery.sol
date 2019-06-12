pragma solidity >=0.4.21 <0.6.0;

contract Lottery {

    struct BetInfo {
        uint256 answerBlockNumber;
        address payable betPerson;
        byte challenges;
    }

    uint256 private head;
    uint256 private tail;
    mapping(uint256=>BetInfo) private betInfoMap;

    address public owner;

    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;
    uint256 constant internal BLOCK_INTERVAL = 3;
    uint256 constant internal BLOCK_LIMIT = 256;

    uint256 private pot;

    enum BlockStatus {BEHIND_BLOCK_LIMIT, ON_THE_BLOCK, OVER_THE_BLOCK, UNKNOWN_STATUS}
    enum BettingResult {WIN, LOSE, DRAW}

    event BET(uint256 index, address betPerson,uint256 amount, uint256 answerBlockNumber, byte challenges);

    constructor() public {
        owner = msg.sender;
    }

    function getValue() public pure returns (uint256 value){
        return 5;
    }

    function getPot() public view returns (uint256 potValue) {
        return pot;
    }

    /**
    @dev 배팅을 하고 , 이더 보내고, 해쉬값 보낸다.
    @param challenges 유저입력해쉬 
    @return 함수 수행여부에 따른 boolean
     */
    function bet(byte challenges) public payable returns (bool result) {
        require(msg.value == BET_AMOUNT, 'not enough ETH');
        require(pushBet(challenges), 'cant pushBet');
        emit BET(tail-1, msg.sender,msg.value, block.number+BLOCK_INTERVAL, challenges);

        return true;
    }

    /**distribute bet ETH by result */
    function distribute() public {
        uint256 flag;
        BetInfo memory b;
        BlockStatus currentStatus;

        for(flag=head;flag<tail;flag++){
            b = betInfoMap[flag];
            currentStatus = getBlockStatus(b.answerBlockNumber);

            if(currentStatus == BlockStatus.BEHIND_BLOCK_LIMIT) {
                //refund
                //emit refund event
            } else if(currentStatus == BlockStatus.ON_THE_BLOCK) {
                // win => get pot money

                // lose => pay pot money

                // draw => refund bet money

            } else if(currentStatus == BlockStatus.OVER_THE_BLOCK) {
                break;
            }

            popBet(flag);
        }
    }

    function betAndDistribute(byte chall) public payable returns (bool){
        bet(chall);
        distribute();
        return true;
    }

    /** check between challenge and hashnumber*/
    function isMatch(byte challenges, bytes32 answer) public pure returns (BettingResult) {

        byte c1 = challenges;
        byte c2 = challenges;

        c1 = c1 >> 4;    //0x0a
        c1 = c1 << 4;    //0xa0    

        c2 = c2 << 4;    //0xb0
        c2 = c2 >> 4;    //0x0b  

        byte a1 = answer[0];
        byte a2 = answer[0];    

        a1 = a1 >> 4;
        a1 = a1 << 4;  

        a2 = a2 << 4;
        a2 = a2 >> 4;      

        if(a1 == c1 && a2 == c2) {
            return BettingResult.WIN;
        } else if(a1 == c1 || a2 == c2) {
            return BettingResult.DRAW;
        }
        return BettingResult.LOSE;
    }

    /**
    BEHIND_BLOCK_LIMIT => refund
    ON_THE_BLOCK => bet
    OVER_THE_BLOCK=> cancel
     */
    function getBlockStatus(uint256 answerBlockNumber) public view returns (BlockStatus){
        if(answerBlockNumber < block.number - BLOCK_LIMIT) {
            return BlockStatus.BEHIND_BLOCK_LIMIT;
        } else if(answerBlockNumber >= block.number - BLOCK_LIMIT && answerBlockNumber < block.number) {
            return BlockStatus.ON_THE_BLOCK;
        } else if(answerBlockNumber >= block.number) {
            return BlockStatus.OVER_THE_BLOCK;
        }
        return BlockStatus.UNKNOWN_STATUS; // prevent unexpected error
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address betPerson, byte challenges) {
        BetInfo memory b = betInfoMap[index];
        answerBlockNumber = b.answerBlockNumber;
        betPerson = b.betPerson;
        challenges = b.challenges;
    }

    // start bet queue
    function pushBet(byte challenges) internal returns (bool){
        BetInfo memory b;

        b.answerBlockNumber = block.number + BLOCK_INTERVAL;
        b.betPerson = msg.sender;
        b.challenges = challenges;

        betInfoMap[tail] = b;
        tail++;

        return true;
    }

    // end bet queue
    function popBet(uint256 index) public returns (bool){
        delete betInfoMap[index];
        
        return true;   
    }
}