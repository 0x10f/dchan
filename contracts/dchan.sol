contract DChan {
    uint256 private constant NULL_REF = 0xffffff;

    uint256 private constant FLAG_QUEUE_HEAD  = 0x1;
    uint256 private constant FLAG_QUEUE_TAIL  = 0x2;
    uint256 private constant MASK_QUEUE_HEAD  = 0xffffff0000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MASK_QUEUE_TAIL  = 0x000000ffffff0000000000000000000000000000000000000000000000000000;
    uint256 private constant SHIFT_QUEUE_HEAD = 232;
    uint256 private constant SHIFT_QUEUE_TAIL = 208;

    uint256 private constant FLAG_POST_NEXT         = 0x1;
    uint256 private constant FLAG_POST_AUTHOR       = 0x2;
    uint256 private constant FLAG_POST_DIGEST_FN    = 0x4;
    uint256 private constant FLAG_POST_DIGEST_SIZE  = 0x8;
    uint256 private constant MASK_POST_NEXT         = 0xffffff0000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MASK_POST_AUTHOR       = 0x000000ffffffffffffffffffffffffffffffffffffffff000000000000000000;
    uint256 private constant MASK_POST_DIGEST_FN    = 0x0000000000000000000000000000000000000000000000ff0000000000000000;
    uint256 private constant MASK_POST_DIGEST_SIZE  = 0x000000000000000000000000000000000000000000000000ff00000000000000;
    uint256 private constant SHIFT_POST_NEXT        = 232;
    uint256 private constant SHIFT_POST_AUTHOR      = 72;
    uint256 private constant SHIFT_POST_DIGEST_FN   = 64;
    uint256 private constant SHIFT_POST_DIGEST_SIZE = 56;

    uint256 private constant FLAG_THREAD_NEXT       = 0x1;
    uint256 private constant FLAG_THREAD_POST_HEAD  = 0x2;
    uint256 private constant FLAG_THREAD_POST_TAIL  = 0x4;
    uint256 private constant FLAG_THREAD_COUNT      = 0x8;
    uint256 private constant MASK_THREAD_NEXT       = 0xffffff0000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MASK_THREAD_POST_HEAD  = 0x000000ffffff0000000000000000000000000000000000000000000000000000;
    uint256 private constant MASK_THREAD_POST_TAIL  = 0x000000000000ffffff0000000000000000000000000000000000000000000000;
    uint256 private constant MASK_THREAD_COUNT      = 0x000000000000000000ffff000000000000000000000000000000000000000000;
    uint256 private constant SHIFT_THREAD_NEXT      = 232;
    uint256 private constant SHIFT_THREAD_PREV      = 208;
    uint256 private constant SHIFT_THREAD_POST_HEAD = 184;
    uint256 private constant SHIFT_THREAD_POST_TAIL = 160;
    uint256 private constant SHIFT_THREAD_POST_TAIL = 144;

    struct Thread {
        uint256 meta;
    }

    struct Post {
        bytes32 digest;
        uint256 meta;
    }

    mapping(uint256 => Thread) private threads;
    uint256 private threadCount;

    uint256 private unallocatedThreads;
    uint256 private allocatedThreads;

    mapping(uint256 => Post) private posts;
    uint256 private postCount;

    uint256 private unallocatedPosts;

    constructor() public {
        unallocatedThreads = encodeQueue(0, NULL_REF, NULL_REF, FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL);
        allocatedThreads   = encodeQueue(0, NULL_REF, NULL_REF, FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL);
        unallocatedPosts   = encodeQueue(0, NULL_REF, NULL_REF, FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL);
    }

    function initializeThreads(
        uint256 n
    )
        public
    {

    }

    function initializePosts(
        uint256 n
    )
        public
    {

    }

    function post(
        uint256 threadID,
        uint256 digestFn,
        uint256 digestSize,
        bytes32 digest
    )
        public
    {
        uint256 scratch;
        if (threadID == 0) {
            threadID = allocateThread();
            scratch |= 0x1;
        }

        uint256 postID = allocatePost();

        if ((scratch & 0x1) != 0) {
            (uint256 head, uint256 tail) = decodeQueue(allocatedThreads);

            threads[threadID] = Thread({
                meta: encodeThreadMetadata(
                    0,
                    tail,
                    NULL_REF,
                    postID,
                    postID,
                    1,
                    FLAG_THREAD_NEXT      |
                    FLAG_THREAD_POST_HEAD |
                    FLAG_THREAD_POST_TAIL |
                    FLAG_THREAD_COUNT
                )
            });

            posts[postID] = Post({
                digest: digest,
                meta:   encodePostMetadata(
                    0,
                    NULL_REF,
                    msg.sender,
                    digestFn,
                    digestSize,
                    FLAGS_POST_NEXT        |
                    FLAGS_POST_AUTHOR      |
                    FLAGS_POST_DIGEST_FN   |
                    FLAGS_POST_DIGEST_SIZE
                )
            });
        } else {
            (uint256 head, uint256 tail) = decodeQueue(allocatedThreads);

            uint256 meta = threads[threadID].meta;

            threads[threadID] = Thread({
                meta: encodeThreadMetadata(
                    meta,
                    tail,
                    NULL_REF,
                    0,
                    postID,
                    1,
                    FLAG_THREAD_NEXT      |
                    FLAG_THREAD_POST_TAIL |
                    FLAG_THREAD_COUNT
                )
            });

            posts[postID] = Post({
                digest: digest,
                meta:   encodePostMetadata(
                    0,
                    NULL_REF,
                    msg.sender,
                    digestFn,
                    digestSize,
                    FLAGS_POST_NEXT        |
                    FLAGS_POST_AUTHOR      |
                    FLAGS_POST_DIGEST_FN   |
                    FLAGS_POST_DIGEST_SIZE
                )
            });
        }
    }

    function decodeQueue(
        uint256 value
    )
        public
        pure
        returns (uint256 head, uint256 tail)
    {
        return (
            (value & MASK_QUEUE_HEAD) >> SHIFT_QUEUE_HEAD,
            (value & MASK_QUEUE_TAIL) >> SHIFT_QUEUE_TAIL
        );
    }

    function decodeQueueHead(
        uint256 value
    )
        public
        pure
        returns (uint256)
    {
        return (value & MASK_QUEUE_HEAD) >> SHIFT_QUEUE_HEAD;
    }

    function decodeQueueTail(
        uint256 value
    )
        public
        pure
        returns (uint256)
    {
        return (value & MASK_QUEUE_TAIL) >> SHIFT_QUEUE_TAIL;
    }

    function encodeQueue(
        uint256 value,
        uint256 head,
        uint256 tail,
        uint256 flags
    )
        public
        pure
        returns (uint256)
    {
        if ((flags & FLAG_QUEUE_HEAD) != 0) {
            value = (value & ~MASK_QUEUE_HEAD) | (head << SHIFT_QUEUE_HEAD);
        }

        if ((flags & FLAG_QUEUE_TAIL) != 0) {
            value = (value & ~MASK_QUEUE_TAIL) | (tail << SHIFT_QUEUE_TAIL);
        }

        return value;
    }

    function decodeThreadNext(
        uint256 value
    )
        public
        pure
        returns (uint256)
    {
        return (value & MASK_THREAD_NEXT) >> SHIFT_THREAD_NEXT;
    }

    function decodeThreadMetadata(
        uint256 value
    )
        public
        pure
        returns (
            uint256 next,
            uint256 prev,
            uint256 postsHead,
            uint256 postsTail,
            uint256 count
        )
    {
        return (0, 0, 0, 0, 0);
    }

    function encodeThreadMetadata(
        uint256 value,
        uint256 prev,
        uint256 next,
        uint256 postHead,
        uint256 postTail,
        uint256 count,
        uint256 flags
    )
        public
        pure
        returns (uint256 meta)
    {
        return 0;
    }

    function decodePostMetadata(uint256 value)
        public
        pure
        returns (
            uint256 next,
            address author,
            uint256 digestFn,
            uint256 digestSize
        )
    {
        return (0, 0, 0, 0);
    }

    function decodePostNext(
        uint256 value
    )
        public
        pure
        returns (uint256)
    {
        return (value & MASK_POST_NEXT) >> SHIFT_POST_NEXT;
    }

    function encodePostMetadata(
        uint256 value,
        uint256 next,
        address author,
        uint256 digestFn,
        uint256 digestSize,
        uint256 flags
    )
        public
        pure
        returns (uint256 meta)
    {
        return 0;
    }

    function allocateThread()
        private
        view
        returns (uint256 id)
    {
        (uint256 head, uint256 tail) = decodeQueue(unallocatedThreads);
        require(head != NULL_REF);

        if (head == tail) {
            unallocatedThreads = encodeQueue(0, NULL_REF, NULL_REF, FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL);
        } else {
            unallocatedThreads = encodeQueue(
                0,
                decodeThreadNext(threads[head].meta),
                tail,
                FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL
            );
        }

        return head;
    }

    function allocatePost()
        private
        view
        returns (uint256 id)
    {
        (uint256 head, uint256 tail) = decodeQueue(unallocatedPosts);
        require(head != NULL_REF);

        if (head == NULL_REF) {
            return NULL_REF;
        }

        if (head == tail) {
            unallocatedPosts = encodeQueue(0, NULL_REF, NULL_REF, FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL);
        } else {
            unallocatedPosts = encodeQueue(
                0,
                decodeThreadNext(posts[head].meta),
                tail,
                FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL
            );
        }

        return head;
    }
}