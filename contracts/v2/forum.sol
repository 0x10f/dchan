pragma solidity ^0.5.1;

library DChan {
    uint256 private constant NULL_PAGE = 0x1;

    // When a page is initialized:
    // - All of the words of memory must be initialized to a non-zero value.
    // - It must be appended to the queue of 'free' pages.
    struct Page {
        uint256 id;

        // Prev is a reusable reference to the previous page in a linked list
        // structure that the page may optionally be apart of.
        uint256 prev;

        // Next is reusable reference to the next page in a linked list structure
        // that the page may optionally be apart of.
        uint256 next;

        // Words is all of the words of memory that comprise a page. All words
        // *must* throughout the lifetime of a page be set to a non-zero value.
        mapping(uint256 => bytes32) words;
    }

    // IsLinked returns if the provided page is a member of a linked list.
    function isLinked(Page memory page) internal pure returns (bool) {
        return page.prev != NULL_PAGE;
    }

    struct Database {
        // InitializedPages is the counter which specifies the current number memory pages
        // of memory that have been initialized.
        uint256 initializedPages;

        // Pages are all of the pages of memory that are contained within the contract.
        mapping(uint256 => Page) pages;
    }
}

// Memory
// ------
contract Forum {
    // MaximumContentLength defines the maximum number of words that the content of
    // a post can be.
    uint256 public maximumContentLength;

    // Maximum pages defines the current maximum number of pages that can exist.
    uint256 public maximumPages;

    // Init initializes the contract and marks that it is ready to be used.
    function init(
        uint256 _maximumContentLength,
        uint256 _maximumPages
    ) public {
        revert("Not yet implemented.");
    }

    // IsInitialized is a modifier which is prepended to functions to immediately
    // revert if the contract has not yet been initialized.
    modifier isInitialized() {
        _;
    }

    // When a page is initialized:
    // - All of the words of memory must be initialized to a non-zero value.
    // - It must be appended to the queue of 'free' pages.
    struct Page {
        // Prev is a reusable reference to the previous page in a linked list
        // structure that the page may optionally be apart of.
        uint256 prev;

        // Next is reusable reference to the next page in a linked list structure
        // that the page may optionally be apart of.
        uint256 next;

        // Words is all of the words of memory that comprise a page. All words
        // *must* throughout the lifetime of a page be set to a non-zero value.
        mapping(uint256 => bytes32) words;
    }

    struct Queue {
        // The reference to the page that is the root of the queue. The page will
        // be uninitialized and only used for the purpose of serving as a tentative
        // placeholder for for when the the queue is empty or traversing.
        uint256 root;
    }

    // InitializedPages is the counter which specifies the current number memory pages
    // of memory that have been initialized.
    uint256 initializedPages;

    // Pages are all of the pages of memory that are contained within the contract.
    mapping(uint256 => Page) pages;

    // UnallocatedPages is queue of all the free pages.
    Queue unallocatedPages;

    // InitializeMemory initializes pages of memory and returns the number of
    // pages that were successfully  initialized. The number of pages that can
    // be initialized is dependant on the current number of initialized pages
    // and the current maximum number of pages allowed to be initialized. If
    // no pages were successfully initialized, this function reverts.
    function initializeMemory(uint256 pages) public payable returns (uint256 count) {
        revert("Not implemented");
    }

    // AllocatePage allocates or reserves a single page of memory and returns
    // its identifier. If a page could not be allocated then this function
    // returns zero.
    function allocateMemory() private returns (uint256 id) {
        revert("Not implemented");
    }
}