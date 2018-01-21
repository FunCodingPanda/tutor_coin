pragma solidity ^0.4.11;

import './ERC20.sol';


//name this contract whatever you'd like
contract TutorCoin is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = '1.0';

    /* Public Constants */
    ufixed public rewardFraction = 0.001;
    uint public maxUpvotes = 100;
    uint public maxAnswers = 10;
    uint256 public minReward = 0.001;

    /**
     * ------------------------------
     * Structures
     * ------------------------------
     */

    struct Question {
        string contents;
        address student;
        uint askTime;
        uint256 bounty;
        uint256 totalReward;
        int numUpvotes;
    }

    struct Answer {
        string contents;
        address tutor;
        int numUpvotes;
    }

    /**
     * ------------------------------
     * Global Public Addresses
     * ------------------------------
     */

    /* The master address stores the rewards pool */
    address public master = 0x1000000000000000000000000000000000000000;
    /* The pending rewards address holds rewards for a question that will be distributed */
    address public pendingRewards = 0x2000000000000000000000000000000000000000;
    /* The tutor address is owned by the Tutor Coin team */
    address public tutor = 0xa7c0744b966475489694b770be009d0c2c275563;

    /* All questions that have been asked. */
    Question[] public questions;

    /* All answers that have been posted for each question ID. */
    mapping (uint => Answer[]) answers;

    event Mine(address indexed _to, uint256 _value);
    event AwardBounty(address indexed _to, )

    /**
     * ------------------------------
     * Constructor
     * ------------------------------
     */

    function TutorCoin(
        ) {
        totalSupply = 1000000000;
        name = "Tutor Coin";
        decimals = 6;
        symbol = "TUT";
    }

    /**
     * ------------------------------
     * Mining Definitions
     * ------------------------------
     */

    /**
     * @dev Calculate the mining reward
     * @return uint256 Returns the amount to reward
     */
    function calculateMiningReward() returns (uint256 reward) {
        uint256 totalSupply = getTokenBalance();

        /* Check if we are incrementing reward */
        if (incrementalRewards == true) {
            uint maxReward = (totalSupply * maxRewardPercent/100);
            reward = (totalSupply * (now - timeOfLastProof) / 1 years);
            if (reward > maxReward) reward = maxReward; // Make sure reward does not exceed maximum percent
        } else {
            reward = baseReward;
        }

        if (reward > totalSupply) return totalSupply;

        return reward;
    }

    /**
     * @notice Proof of work to be done for mining
     * @param _nonce uint256
     * @return uint256 The amount rewarded
     */
    function proofOfWork(uint _nonce) returns (uint256 _reward) {
        bytes32 n = sha3(_nonce, currentChallenge); // generate random hash based on input
        require(n <= bytes32(difficulty));

        uint timeSinceLastProof = (now - timeOfLastProof); // Calculate time since last reward
        require(timeSinceLastProof >= 5 seconds); // Do not reward too quickly

        _reward = calculateMiningReward();

        // Send 45% of the reward to the miner, 45% to the master pool, and 10% to Tutor creators
        balances[msg.sender] += _reward * 0.45;
        balances[master] += _reward * 0.45;
        balances[tutor] += _reward * 0.1;

        difficulty = difficulty * 10 minutes / timeSinceLastProof + 1; // Adjusts the difficulty
        timeOfLastProof = now;
        currentChallenge = sha3(_nonce, currentChallenge, block.blockhash(block.number - 1)); // Save hash for next proof

        Mine(msg.sender, _reward); // execute an event reflecting the change

        return _reward;
    }

    /**
     * ------------------------------
     * Questions, Answers, Upvotes, and Rewards
     * ------------------------------
     */

    /**
     * @notice Ask a question, providing a bounty to reward tutors who answer
     * @param _bounty The optional bounty reward that the student wants to offer
     * @param _contents The text of the student's question
     * @return Whether asking the question was successful
     */
    function askQuestion(uint256 _bounty, string _contents) returns (bool success) {
        if (balances[msg.sender] >= _bounty) {
            // Calculate the total reward for this question
            uint256 total_reward = rewardFraction * balance[master];

            // Add the question to the blockchain
            questions.push(Question({
                contents: _contents,
                student: msg.sender,
                askTime: now,
                bounty: _bounty,
                totalReward: total_reward,
                numUpvotes: 0
            }));

            // Student gets an initial reward
            uint256 initial_reward = calculateReward(len(questions) - 1, now);

            // Set up rewards
            balances[msg.sender] += initial_reward;
            balances[msg.sender] -= _bounty;
            balances[master] -= total_reward;
            balances[pendingRewards] += total_reward + _bounty - initial_reward;

            // Publish events
            Transfer(master, pendingRewards, total_reward);
            Transfer(msg.sender, pendingRewards, _bounty);
            Transfer(pendingRewards, msg.sender, initial_reward);
            return true;
        } else {
            return false;
        }
    }

    function calculateReward(uint _question_id, uint _time) {
        Question question = questions[_question_id];
        uint rTotal = question.totalReward;
        uint rMax = rTotal / (maxAnswers + 1);
        uint timeSinceAsked = _time - question.askTime;
        uint timeFactor = 1 / (1 + timeSinceAsked);
        uint upvoteFactor = 1 / (1 + maxUpvotes);
        return rMax * timeFactor * upvoteFactor;
    }

    function answerQuestion(uint _question_id) returns (bool success) {
        // Add answer to blockchain
        // Take small reward from pendingRewards
    }

    function upvoteAnswer(uint _answer_id) returns (bool success) {
        // Subtract balance from pendingRewards
        // Add balance to tutor who answered
    }

    function upvoteQuestion(uint _question_id) returns (bool success) {
        Question question = questions[_question_id];
        // Ensure students can't upvote themselves
        if (msg.sender == question.student || question.numUpvotes == maxUpvotes) {
            return false;
        } else {
            reward = calculateReward(_question_id, question.askTime);
            balances[question.student] += reward;
            balances[pendingRewards] -= reward;

            // Increment upvotes
            questions[_question_id].numUpvotes += 1;

            // Transfer reward to student
            Transfer(pendingRewards, question.student, reward);
            return true;
        }
    }

    function downvoteAnswer(uint _answer_id) returns (bool success) {
        // Subtract balance from tutor (but ensure > 0)
        // Add balance back to pendingRewards
    }

    function downvoteQuestion(uint _question_id) returns (bool success) {
        // Subtract balance from student (but ensure > 0)
        // Add balance back to pendingRewards
    }

    function acceptAnswer(uint _question_id, uint _answer_id) returns (bool success) {
        // Verify msg.sender is question.student
        // Subtract bounty from pendingRewards
        // Send bounty to tutor with accepted answer
    }

    function claimLeftovers(uint _question_id) returns (bool success) {
        // Check if current time is larger than t_max, and if so take leftovers
    }
}
