pragma solidity ^0.5.1;

contract Forum {
    uint128 private constant NULL_REF  = 0xffffffffffffffffffffffffffffffff;
    bytes32 private constant NULL_WORD = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // MaximumContentLength defines the maximum number of words that the content of
    // a post can be.
    uint256 public maximumContentLength;

    // MaximumPages defines the current maximum number of pages that can exist.
    uint256 public maximumPages;

    // MaximumPosts defines the current maximum number of posts that can exist.
    uint256 public maximumPosts;

    uint256 public maximumThreads;

    bool private initialized;

    // Init initializes the contract and marks that it is ready to be used.
    function init(
        uint256 _maximumContentLength,
        uint256 _maximumPages,
        uint256 _maximumPosts,
        uint256 _maximumThreads
    ) public {
        maximumContentLength = _maximumContentLength;
        maximumPages = _maximumPages;
        maximumPosts = _maximumPosts;
        maximumThreads = _maximumThreads;

        unallocatedPages.head = NULL_REF;
        unallocatedPages.tail = NULL_REF;

        unallocatedPosts.head = NULL_REF;
        unallocatedPosts.tail = NULL_REF;

        unallocatedThreads.head = NULL_REF;
        unallocatedThreads.tail = NULL_REF;

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

    // Queue is a generic structure used for singly or doubly linked lists. The
    // list assumes that the objects referred to in the queue use an 128 bit
    // identifier. This is to conserve gas when updating the queue references.
    struct Queue {
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
    Queue unallocatedPages;

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
                next: NULL_REF,
                words: new bytes32[](maximumContentLength)
            });

            for (uint256 j = 0; j < maximumContentLength; j++) {
                page.words[j] = NULL_WORD;
            }

            pages[id] = page;

            // If the free page list is not empty, append the page as the tail.
            // Otherwise, initialize the list.
            if (unallocatedPages.tail != NULL_REF) {
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
        if (unallocatedPages.head == NULL_REF) {
            return NULL_REF;
        }

        // TODO(271): Determine if it is wise to set the next node.
        uint128 id = unallocatedPages.head;

        if (id == unallocatedPages.tail) {
            unallocatedPages.head = NULL_REF;
            unallocatedPages.tail = NULL_REF;
        } else {
            unallocatedPages.head = pages[id].next;
        }

        return id;
    }

    struct Post {
        // Next is the
        uint128 next;

        // PageID is the identifier of the page where the post contents start.
        uint128 pageID;

        // Offset is the starting word in the page that the post occupies.
        uint128 offset;

        // Length is the length of the post in words.
        uint128 length;
    }

    // Posts are all of the posts that are contained within the contract.
    mapping(uint256 => Post) posts;

    // InitializedPageCount is a counter which is equal to the current number of posts
    // pages that have been initialized.
    uint128 initializedPostCount;

    // UnallocatedPosts is queue of all the posts that are currently not being used
    // by threads.
    Queue unallocatedPosts;

    function initializePosts(uint256 n) isInitialized public returns (uint256 count) {
        require(initializedPostCount < maximumPosts, "Posts already allocated.");

        uint256 remaining = maximumPosts - initializedPostCount;
        if (n > remaining) {
            n = remaining;
        }

        uint128 counter = initializedPostCount;

        for (uint256 i = 0; i < n; i++) {
            uint128 id = counter + 1;

            Post memory post = Post({
                next:   NULL_REF,
                pageID: NULL_REF,
                offset: NULL_REF,   // TODO
                length: NULL_REF
            });

            posts[id] = post;

            if (unallocatedPosts.tail != NULL_REF) {
                Post storage tail = posts[unallocatedPosts.tail];
                tail.next = id;

                unallocatedPosts.tail = id;
            } else {
                unallocatedPosts.head = id;
                unallocatedPosts.tail = id;
            }

            counter++;
        }

        initializedPostCount = counter;

        return n;
    }

    function allocatePost() isInitialized private returns (uint128 id) {
        if (unallocatedPosts.head == NULL_REF) {
            return NULL_REF;
        }

        // TODO(271): Determine if it is wise to set the next node.
        uint128 id = unallocatedPosts.head;

        if (id == unallocatedPosts.tail) {
            unallocatedPosts.head = NULL_REF;
            unallocatedPosts.tail = NULL_REF;
        } else {
            unallocatedPosts.head = posts[id].next;
        }

        return id;
    }

    struct Thread {
        Queue pages;

        Queue posts;

        uint128 next;

        uint128 count;
    }

    // Posts are all of the posts that are contained within the contract.
    mapping(uint256 => Thread) threads;

    // InitializedPageCount is a counter which is equal to the current number of threads
    // that have been initialized.
    uint128 initializedThreadCount;

    // UnallocatedThreads is queue of all the threads that are currently not being used.
    Queue unallocatedThreads;

    function initializeThreads(uint256 n) isInitialized public returns (uint256 count) {
        require(initializedThreadCount < maximumThreads, "Threads already allocated.");

        uint256 remaining = maximumThreads - initializedThreadCount;
        if (n > remaining) {
            n = remaining;
        }

        // TODO(271): Casting up to reduce gas costs.
        uint128 counter = initializedThreadCount;

        for (uint256 i = 0; i < n; i++) {
            uint128 id = counter + 1;

            Thread memory thread = Thread({
                pages:  Queue({head: NULL_REF, tail: NULL_REF}),
                posts:  Queue({head: NULL_REF, tail: NULL_REF}),
                next:   NULL_REF,
                count:  NULL_REF
            });

            threads[id] = thread;

            if (unallocatedThreads.tail != NULL_REF) {
                Thread storage tail = threads[unallocatedThreads.tail];
                tail.next = id;

                unallocatedThreads.tail = id;
            } else {
                unallocatedThreads.head = id;
                unallocatedThreads.tail = id;
            }

            counter++;
        }

        initializedThreadCount = counter;

        return n;
    }

    function allocateThread() isInitialized private returns (uint128 id) {
        if (unallocatedThreads.head == NULL_REF) {
            return NULL_REF;
        }

        // TODO(271): Determine if it is wise to set the next node.
        uint128 id = unallocatedThreads.head;

        if (id == unallocatedThreads.tail) {
            unallocatedThreads.head = NULL_REF;
            unallocatedThreads.tail = NULL_REF;
        } else {
            unallocatedThreads.head = threads[id].next;
        }

        return id;
    }

    function publish(bytes32[] memory content) public {
        require(content.length < maximumContentLength, "Content is too long.");

        // TODO: Assuming post is to create a new thread.

        // Allocate a new post that we can use to write the data to.
        uint128 postID = allocatePost();
        require(postID != NULL_REF, "Failed to allocate post.");

        // Since we are creating a new thread we *must* allocate a page of memory.
        uint128 pageID = allocateMemory();
        require(pageID != NULL_REF, "Failed to allocate page.");

        // Allocate and set the thread up by doing the following:
        // - Initializing the page queue.
        // - Initializing the post queue.
        // - Initializing the post counter.
        uint128 threadID = allocateThread();
        require(threadID != NULL_REF, "Failed to allocate thread.");

        Thread storage thread = threads[threadID];

        thread.pages.head = pageID;
        thread.pages.tail = pageID;

        thread.posts.head = postID;
        thread.posts.tail = postID;

        thread.count = 1;

        // Set the post up by doing the following:
        // - Setting the page that the post occupies.
        // - Setting the offset and length of the post in words.
        Post storage post = posts[postID];

        post.pageID = pageID;

        post.offset = 0;
        post.length = uint128(content.length);

        // Write the content to the page that the post occupies.
        Page storage page = pages[pageID];

        for (uint256 i = 0; i < content.length; i++) {
            page.words[i] = content[i];
        }
    }
}