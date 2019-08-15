pragma solidity ^0.5.1;

contract Forum {
    uint128 private constant NULL_PAGE = 0xffffffffffffffffffffffffffffffff;
    bytes32 private constant NULL_WORD = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // MaximumContentLength defines the maximum number of words that the content of
    // a post can be.
    uint256 public maximumContentLength;

    // MaximumPages defines the current maximum number of pages that can exist.
    uint256 public maximumPages;

    bool private initialized;

    // Init initializes the contract and marks that it is ready to be used.
    function init(
        uint256 _maximumContentLength,
        uint256 _maximumPages
    ) public {
        maximumContentLength = _maximumContentLength;
        maximumPages = _maximumPages;

        unallocatedPages.head = NULL_PAGE;
        unallocatedPages.tail = NULL_PAGE;

        initialized = true;
    }

    // IsInitialized is a modifier which is prepended to functions to immediately
    // revert if the contract has not yet been initialized.
    modifier isInitialized() {
        require(initialized, "Contract has not yet been initialized.");
        _;
    }

    // GetMaximumContentLengthBytes returns the maximum number of bytes that the
    // content of a post can be.
    function getMaximumContentLengthBytes() public view returns (uint256) {
        return maximumContentLength << 5;
    }

    struct Page {
        uint128 id;
        uint128 next;
        bytes32[] words;
    }

    struct PageQueue {
        uint128 head;
        uint128 tail;
    }

    // Pages are all of the pages of memory that are contained within the contract.
    mapping(uint256 => Page) pages;

    // InitializedPageCount is a counter which is equal to the current number of memory
    // pages that have been initialized.
    uint128 initializedPageCount;

    // UnallocatedPages is queue of all the pages that are currently not being used
    // by threads.
    PageQueue unallocatedPages;

    // InitializeMemory initializes pages of memory and returns the number of
    // pages that were successfully initialized. The number of pages that can
    // be initialized is dependant on the current number of initialized pages
    // and the current maximum number of pages allowed to be initialized. If
    // no pages were successfully initialized, this function reverts.
    function initializeMemory(uint256 n) isInitialized public returns (uint256 count) {
        require(initializedPageCount < maximumPages, "Pages already allocated.");

        // Limit the number of pages to being at most the number of pages needed
        // to reach the maximum number of pages.
        uint256 remaining = maximumPages - initializedPageCount;
        if (n > remaining) {
            n = remaining;
        }

        // Copy the current number of initialized pages into local
        // memory. This is so that we can update it as we execute
        // the function and then write the value at the end.
        uint128 counter = initializedPageCount;

        for (uint256 i = 0; i < n; i++) {
            // Page identifiers start at zero so offset from the counter
            // by one. This is to assure that all values associated
            // with pages are non-zero and after initialization always
            // incur being updated (5000 gas) rather than being deleted
            // and reinitialized.
            uint128 id = counter + 1;

            // Initialize the page in memory and then copy it into storage.
            Page memory page = Page({
                id:    id,
                next:  NULL_PAGE,
                words: new bytes32[](maximumContentLength)
            });

            for (uint256 j = 0; j < maximumContentLength; j++) {
                page.words[j] = NULL_WORD;
            }

            pages[id] = page;

            // If the free page list is not empty, append the page as the tail.
            // Otherwise, initialize the list.
            if (unallocatedPages.tail != NULL_PAGE) {
                Page storage tail = pages[unallocatedPages.tail];
                tail.next = id;

                unallocatedPages.tail = id;
            } else {
                unallocatedPages.head = id;
                unallocatedPages.tail = id;
            }

            counter++;
        }

        initializedPageCount = counter;

        return n;
    }

    // AllocateMemory allocates or reserves a single page of memory and returns
    // its identifier. If a page could not be allocated then this function
    // returns NULL_PAGE.
    function allocateMemory() isInitialized private returns (uint128 id) {
        if (unallocatedPages.head == NULL_PAGE) {
            return NULL_PAGE;
        }

        // TODO(271): Determine if it is wise to set the next node.
        Page memory page = pages[unallocatedPages.head];

        if (unallocatedPages.head == unallocatedPages.tail) {
            unallocatedPages.head = NULL_PAGE;
            unallocatedPages.tail = NULL_PAGE;
        } else {
            unallocatedPages.head = page.next;
        }

        return page.id;
    }
}