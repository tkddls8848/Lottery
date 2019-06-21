const Lottery = artifacts.require('Lottery');
const assertRevert = require('./assertRevert');
const expectEvent = require('./expectEvent');

contract('Lottery', ([deployer, user1, user2]) => {

    let lottery;
    let betAmount = 5000000000000000;
    let betAmountBN = new web3.utils.BN('5000000000000000');
    let BLOCK_INTERVAL = 3;

    beforeEach( async() => {
        lottery = await Lottery.new();
        console.log('new lottery');
    });

    it('getValue test', async () => {
        let owner = await lottery.owner();
        let value = await lottery.getValue();
        assert.equal(value , 5);
        console.log(`owner : ${owner}`)
    });

    it('pot test', async () => {
        let pot = await lottery.getPot();
        assert.equal(pot, 0);
        console.log(`pot : ${pot}`);
    });

    describe('Bet', () => {
        //fail transaction
        it('bet money is not 0.005 ETH', async () => {
            await assertRevert(lottery.bet('0xab', {from : user1, value:4000000000000000}));
        })
        //success transaction
        it('success transaction', async () => {
            let reciept = await lottery.bet('0xab', {from : user1, value:5000000000000000});

            let potMoney = await lottery.getPot();
            assert.equal(potMoney, 0);

            let contractBalance = await web3.eth.getBalance(lottery.address);
            assert.equal(contractBalance, betAmount);

            let betInfo = await lottery.getBetInfo(0);
            assert.equal(betInfo.answerBlockNumber, await web3.eth.getBlockNumber() + BLOCK_INTERVAL);
            assert.equal(betInfo.betPerson, user1);
            assert.equal(betInfo.challenges, '0xab');
            
            await expectEvent.inLogs(reciept.logs, 'BET')
        })
    })

    describe('isMatch', () => {
        let answer = '0xf3048ff1242af31bedd9f462ebd14d49f43423ee9342b278cdd847cc78fdf0a9';
        it('get win when 2 character matches', async () => {
            let result = await lottery.isMatch('0xf3', answer);
            assert.equal(result, 0);
        });
        it('get draw when 1 character matches', async () => {
            let result = await lottery.isMatch('0x03', answer);
            assert.equal(result, 2);
            
            result = await lottery.isMatch('0xf0', answer);
            assert.equal(result, 2);
        });
        it('get lose when no character matches', async () => {
            let result = await lottery.isMatch('0x12', answer);
            assert.equal(result, 1);
        });
    })


    describe.only('distribute', () => {
        describe('ON_THE_BLOCK', () => {
            it('WIN transfer', async () => {

                await lottery.setAnswerForTest('0xf3048ff1242af31bedd9f462ebd14d49f43423ee9342b278cdd847cc78fdf0a9', {from:deployer});

                await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 1, user2 wrong -> answer for block 4
                await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 2, user2 wrong -> answer for block 5
                await lottery.betAndDistribute('0xf3',{from:user1, value:betAmount}); //block 3, user1 right -> answer for block 6
                await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 4, user2 wrong -> answer for block 7
                await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 5, user2 wrong -> answer for block 8
                await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 6, user2 wrong -> answer for block 9

                let potBefore = await lottery.getPot();
                let user1Before = await web3.eth.getBalance(user1);

                let recipt7 = await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 7, user2 wrong -> answer for block 10

                let potAfter = await lottery.getPot();
                let user1After = await web3.eth.getBalance(user1);

               assert.equal(potBefore.toString(), 2*betAmountBN.toString()); //배팅 실패로 인한 pot 적립
               assert.equal(potAfter.toString(), '0');//배팅 성공으로 인한 pot 초기화
                //배팅 성공으로 인한 잔고확인
               user1BalanceBefore = new web3.utils.BN(user1Before);
               assert.equal(user1BalanceBefore.add(potBefore).add(betAmountBN).toString(), new web3.utils.BN(user1After).toString())
            
            });      
            it.only('LOSE transfer', async () => {

                await lottery.setAnswerForTest('0xf3048ff1242af31bedd9f462ebd14d49f43423ee9342b278cdd847cc78fdf0a9', {from:deployer});

                await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 1, user2 wrong -> answer for block 4
                await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 2, user2 wrong -> answer for block 5
                await lottery.betAndDistribute('0x12',{from:user1, value:betAmount}); //block 3, user1 wrong -> answer for block 6
                await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 4, user2 wrong -> answer for block 7
                await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 5, user2 wrong -> answer for block 8
                await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 6, user2 wrong -> answer for block 9

                let potBefore = await lottery.getPot();
                let user1Before = await web3.eth.getBalance(user1);

                let recipt7 = await lottery.betAndDistribute('0x12',{from:user2, value:betAmount}); //block 7, user2 wrong -> answer for block 10

                let potAfter = await lottery.getPot();
                let user1After = await web3.eth.getBalance(user1);

                // pot 의 변화량 확인
                assert.equal(potBefore.add(betAmountBN).toString(), potAfter.toString());
            
                // 잔고의 변화량 확인
                assert.equal(new web3.utils.BN(user1Before).toString(), new web3.utils.BN(user1After).toString())
            }); 
        })
        describe('BEHIND_BLOCK', async () => {
            //ganache-cli evm_miner를 수행하여 블럭을 건너뛰는 것으로 테스트
        })
    })
});