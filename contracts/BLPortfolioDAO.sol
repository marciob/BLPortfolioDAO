// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BLPortfolioDAO is ERC20, Ownable {
    /**
     * @dev Represents an individual's view on the expected percentage return of a token.
     * @param user The address expressing the view.
     * @param votingPower User's voting power determined by DAO token holdings.
     * @param expectedReturnPercentage User's expected percentage return for the token.
     */
    struct TokenView {
        address user;
        uint256 votingPower;
        int256 expectedReturnPercentage; // Represented in basis points, e.g., 100 = 1%
    }

    /**
     *  @dev Represents the views in a given round for ETH and UNI tokens.
     *  Each field captures the view of the user with the highest voting power for the respective token.
     */
    struct RoundView {
        TokenView ethView;
        TokenView uniView;
    }

    /// @dev Stores the views of the highest voting power users for each round (indexed by round number)
    mapping(uint256 => RoundView) public roundViews;

    /// @dev Tracks the current round number. Each round captures the views of the highest voting power users
    uint256 public currentRound = 1;

    /// @dev Timestamp indicating when the current round started.
    uint256 public roundStartTime;

    /// @dev Represents the view of the user with the highest voting power across all views in the current round
    TokenView public topVoterViewCurrentRound;

    /// @dev Emitted at the end of each round to announce the views of the user with the highest voting power for ETH and UNI tokens views
    event TopVoterView(
        uint256 round,
        address user,
        int256 expectedReturnPercentageETH,
        int256 expectedReturnPercentageUNI
    );

    uint256 constant ROUND_DURATION = 7 days;

    mapping(address => bool) public hasJoinedDAO;

    constructor() ERC20("DAO Governance Token", "DGT") {
        roundStartTime = block.timestamp;
    }

    modifier inRoundTime() {
        require(
            block.timestamp <= roundStartTime + ROUND_DURATION,
            "Round has ended"
        );
        _;
    }

    /**
     * @dev Allows a user to join the DAO by sending ETH. In return, the user receives DAO tokens.
     * Once a user has joined the DAO, they cannot join again from the same address.
     */
    function joinDAO() public payable {
        require(
            !hasJoinedDAO[msg.sender],
            "Address has already joined the DAO"
        );

        require(msg.value >= 0.1 ether, "Minimum 0.1 ETH required");

        uint256 tokenAmount = msg.value;

        _mint(msg.sender, tokenAmount);

        hasJoinedDAO[msg.sender] = true;
    }

    /**
     * @dev Allows DAO members to express their view on the expected percentage return for ETH and UNI tokens.
     * The view is saved for the current round, and if a user has more voting power than the current dominant view, their view becomes dominant
     *
     * @param expectedReturnPercentageETH Expected percentage return for ETH (in basis points).
     * @param expectedReturnPercentageUNI Expected percentage return for UNI (in basis points).
     */
    function expressAbsoluteView(
        int256 expectedReturnPercentageETH,
        int256 expectedReturnPercentageUNI
    ) public inRoundTime {
        require(balanceOf(msg.sender) > 0, "Not a DAO member");

        // Construct and store the caller's view for ETH for the current round
        roundViews[currentRound].ethView = TokenView({
            user: msg.sender,
            votingPower: balanceOf(msg.sender),
            expectedReturnPercentage: expectedReturnPercentageETH
        });

        // Construct and store the caller's view for UNI for the current round
        roundViews[currentRound].uniView = TokenView({
            user: msg.sender,
            votingPower: balanceOf(msg.sender),
            expectedReturnPercentage: expectedReturnPercentageUNI
        });

        // Compare the caller's voting power with the current dominant view. If higher, make the caller's ETH view dominant.
        if (balanceOf(msg.sender) > topVoterViewCurrentRound.votingPower) {
            topVoterViewCurrentRound = roundViews[currentRound].ethView;
        }
    }

    /**
     * @dev Finalizes the current round and starts a new round.
     * This function can be called only by the contract owner.
     * The function emits an event with the views of the user with the highest voting power for the round.
     */
    function finalizeRound() public onlyOwner {
        // Ensure the current round duration has passed before finalizing it
        require(
            block.timestamp > roundStartTime + ROUND_DURATION,
            "Round is still ongoing"
        );

        // Emit an event with the views of the user with the highest voting power for the current round
        emit TopVoterView(
            currentRound,
            topVoterViewCurrentRound.user,
            roundViews[currentRound].ethView.expectedReturnPercentage,
            roundViews[currentRound].uniView.expectedReturnPercentage
        );

        // Increment the round number to start the next round
        currentRound++;

        // Set the start time for the new round to the current block timestamp
        roundStartTime = block.timestamp;
    }
}
