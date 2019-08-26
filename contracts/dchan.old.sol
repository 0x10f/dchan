contract DChan {
    uint256 private constant NULL = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 private constant NULL_REF = 0xffffff;
    uint256 private constant LENGTH_REF = 24;

    uint256 private constant TYPE_QUEUE    = 0x1;
    uint256 private constant TYPE_NODE     = 0x2;
    uint256 private constant TYPE_POST     = 0x3;
    uint256 private constant TYPE_THREAD   = 0x4;
    uint256 private constant TYPE_REF_NODE = 0x5;

    uint256 private constant MASK_TYPE  = 0xf000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant SHIFT_TYPE = 252;

    uint256 private constant FLAG_QUEUE_HEAD  = 0x01;
    uint256 private constant FLAG_QUEUE_TAIL  = 0x02;
    uint256 private constant MASK_QUEUE_HEAD  = 0x0ffffff000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MASK_QUEUE_TAIL  = 0x0000000ffffff000000000000000000000000000000000000000000000000000;
    uint256 private constant SHIFT_QUEUE_HEAD = 228;
    uint256 private constant SHIFT_QUEUE_TAIL = 204;

    uint256 private constant FLAG_NODE_NEXT  = 0x01;
    uint256 private constant MASK_NODE_NEXT  = 0x0ffffff000000000000000000000000000000000000000000000000000000000;
    uint256 private constant SHIFT_NODE_NEXT = 228;

    uint256 private constant FLAG_POST_NEXT    = 0x01;
    uint256 private constant FLAG_POST_AUTHOR  = 0x02;
    uint256 private constant FLAG_POST_PAGE    = 0x04;
    uint256 private constant FLAG_POST_OFFSET  = 0x08;
    uint256 private constant FLAG_POST_LENGTH  = 0x10;
    uint256 private constant MASK_POST_NEXT    = 0x0ffffff000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MASK_POST_AUTHOR  = 0x0000000ffffffffffffffffffffffffffffffffffffffff00000000000000000;
    uint256 private constant MASK_POST_PAGE    = 0x00000000000000000000000000000000000000000000000ffffff00000000000;
    uint256 private constant MASK_POST_OFFSET  = 0x00000000000000000000000000000000000000000000000000000ffff0000000;
    uint256 private constant MASK_POST_LENGTH  = 0x000000000000000000000000000000000000000000000000000000000ffff000;
    uint256 private constant SHIFT_POST_NEXT   = 228;
    uint256 private constant SHIFT_POST_AUTHOR = 68;
    uint256 private constant SHIFT_POST_PAGE   = 44;
    uint256 private constant SHIFT_POST_OFFSET = 28;
    uint256 private constant SHIFT_POST_LENGTH = 12;

    uint256 private constant FLAG_THREAD_NEXT        = 0x01;
    uint256 private constant FLAG_THREAD_PREV        = 0x02;
    uint256 private constant FLAG_THREAD_PAGES_HEAD  = 0x04;
    uint256 private constant FLAG_THREAD_PAGES_TAIL  = 0x08;
    uint256 private constant FLAG_THREAD_POSTS_HEAD  = 0x10;
    uint256 private constant FLAG_THREAD_POSTS_TAIL  = 0x20;
    uint256 private constant FLAG_THREAD_COUNT       = 0x40;
    uint256 private constant FLAG_THREAD_OFFSET      = 0x80;
    uint256 private constant MASK_THREAD_NEXT        = 0x0ffffff000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MASK_THREAD_PREV        = 0x0000000ffffffff0000000000000000000000000000000000000000000000000;
    uint256 private constant MASK_THREAD_PAGES_HEAD  = 0x000000000000000ffffffff00000000000000000000000000000000000000000;
    uint256 private constant MASK_THREAD_PAGES_TAIL  = 0x00000000000000000000000ffffffff000000000000000000000000000000000;
    uint256 private constant MASK_THREAD_POSTS_HEAD  = 0x0000000000000000000000000000000ffffffff0000000000000000000000000;
    uint256 private constant MASK_THREAD_POSTS_TAIL  = 0x000000000000000000000000000000000000000ffffffff00000000000000000;
    uint256 private constant MASK_THREAD_COUNT       = 0x00000000000000000000000000000000000000000000000ffff0000000000000;
    uint256 private constant MASK_THREAD_OFFSET      = 0x000000000000000000000000000000000000000000000000000ffff000000000;
    uint256 private constant SHIFT_THREAD_NEXT       = 228;
    uint256 private constant SHIFT_THREAD_PREV       = 204;
    uint256 private constant SHIFT_THREAD_PAGES_HEAD = 180;
    uint256 private constant SHIFT_THREAD_PAGES_TAIL = 156;
    uint256 private constant SHIFT_THREAD_POSTS_HEAD = 132;
    uint256 private constant SHIFT_THREAD_POSTS_TAIL = 108;
    uint256 private constant SHIFT_THREAD_COUNT      =  92;
    uint256 private constant SHIFT_THREAD_OFFSET     =  76;

    mapping(uint256 => uint256) private objects;
    uint256 private objectCount;

    uint256 private unallocatedObjects;

    constructor() public {
        unallocatedObjects = encodeQueue(0, NULL_REF, NULL_REF, FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL);
    }

    function initializeObjects(uint256 n) public returns (uint256 count) {
        uint256 counter = objectCount;

        (uint256 head, uint256 tail) = decodeQueue(unallocatedObjects);

        for (uint256 i = 0; i < n; i++) {
            uint256 id = counter + 1;
            objects[id] = encodeNode(0, NULL_REF, FLAG_NODE_NEXT);

            if (tail != NULL_REF) {
                objects[tail] = encodeNode(objects[tail], id, FLAG_NODE_NEXT);
                tail = id;
            } else {
                head = id;
                tail = id;
            }

            counter++;
        }

        unallocatedObjects = encodeQueue(0, head, tail, FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL);

        objectCount = counter;

        return n;
    }

    function post(uint256 threadID, bytes32[] memory data) public {
        createThread(data);
    }

    function checkType(uint256 value, uint256 expected) public pure returns (bool) {
        return (value & MASK_TYPE) >> SHIFT_TYPE == expected;
    }

    function encodeNode(
        uint256 value,
        uint256 next,
        uint256 flags
    )   public
        pure
        returns(uint256)
    {
        if ((flags & FLAG_NODE_NEXT) != 0) {
           value = (value & ~MASK_NODE_NEXT) | (next << SHIFT_NODE_NEXT);
        }

        value = (value & ~MASK_TYPE) | (TYPE_NODE << SHIFT_TYPE);

        return value;
    }

    function decodeNodeNext(
        uint256 value
    )   public
        pure
        returns(uint256)
    {
        return (value & MASK_NODE_NEXT) >> SHIFT_NODE_NEXT;
    }

    function encodeQueue(
        uint256 value,
        uint256 head,
        uint256 tail,
        uint256 flags
    )   public
        pure
        returns (uint256)
    {
        if ((flags & FLAG_QUEUE_HEAD) != 0) {
            value = (value & ~MASK_QUEUE_HEAD) | (head << SHIFT_QUEUE_HEAD);
        }

        if ((flags & FLAG_QUEUE_TAIL) != 0) {
            value = (value & ~MASK_QUEUE_TAIL) | (tail << SHIFT_QUEUE_TAIL);
        }

        value = (value & ~MASK_TYPE) | (TYPE_QUEUE << SHIFT_TYPE);

        return value;
    }

    function decodeQueue(
        uint256 value
    )   public
        pure
        returns (uint256 head, uint256 tail)
    {
        return (
            (value & MASK_QUEUE_HEAD) >> SHIFT_QUEUE_HEAD,
            (value & MASK_QUEUE_TAIL) >> SHIFT_QUEUE_TAIL
        );
    }

    function encodePost(
        uint256 value,
        uint256 next,
        address author,
        uint256 page,
        uint256 offset,
        uint256 length,
        uint256 flags
    )   public
        pure
        returns (uint256)
    {
        if ((flags & FLAG_POST_NEXT) != 0) {
            value = (value & ~MASK_POST_NEXT) | (next << SHIFT_POST_NEXT);
        }

        if ((flags & FLAG_POST_AUTHOR) != 0) {
            value = (value & ~MASK_POST_AUTHOR) | (uint256(author) << SHIFT_POST_AUTHOR);
        }

        if ((flags & FLAG_POST_PAGE) != 0) {
            value = (value & ~MASK_POST_PAGE) | (page << SHIFT_POST_PAGE);
        }

        if ((flags & FLAG_POST_OFFSET) != 0) {
            value = (value & ~MASK_POST_OFFSET) | (offset << SHIFT_POST_OFFSET);
        }

        if ((flags & FLAG_POST_LENGTH) != 0) {
            value = (value & ~MASK_POST_LENGTH) | (length << SHIFT_POST_LENGTH);
        }

        value = (value & ~MASK_TYPE) | (TYPE_POST << SHIFT_TYPE);

        return value;
    }

    function encodeThread(
        uint256 value,
        uint256 next,
        uint256 prev,
        uint256 pagesHead,
        uint256 pagesTail,
        uint256 postsHead,
        uint256 postsTail,
        uint256 count,
        uint256 offset,
        uint256 flags
    )   public
        pure
        returns (uint256)
    {
        if ((flags & FLAG_THREAD_NEXT) != 0) {
            value = (value & ~MASK_THREAD_NEXT) | (next << SHIFT_THREAD_NEXT);
        }

        if ((flags & FLAG_THREAD_PREV) != 0) {
            value = (value & ~MASK_THREAD_PREV) | (prev << SHIFT_THREAD_PREV);
        }

        if ((flags & FLAG_THREAD_PAGES_HEAD) != 0) {
            value = (value & ~MASK_THREAD_PAGES_HEAD) | (pagesHead << SHIFT_THREAD_PAGES_HEAD);
        }

        if ((flags & FLAG_THREAD_PAGES_TAIL) != 0) {
            value = (value & ~MASK_THREAD_PAGES_TAIL) | (pagesTail << SHIFT_THREAD_PAGES_TAIL);
        }

        if ((flags & FLAG_THREAD_POSTS_HEAD) != 0) {
            value = (value & ~MASK_THREAD_POSTS_HEAD) | (postsHead << SHIFT_THREAD_POSTS_HEAD);
        }

        if ((flags & FLAG_THREAD_POSTS_TAIL) != 0) {
            value = (value & ~MASK_THREAD_POSTS_TAIL) | (postsTail << SHIFT_THREAD_POSTS_TAIL);
        }

        if ((flags & FLAG_THREAD_COUNT) != 0) {
            value = (value & ~MASK_THREAD_COUNT) | (count << SHIFT_THREAD_COUNT);
        }

        if ((flags & FLAG_THREAD_OFFSET) != 0) {
            value = (value & ~MASK_THREAD_OFFSET) | (offset << SHIFT_THREAD_OFFSET);
        }

        value = (value & ~MASK_TYPE) | (TYPE_THREAD << SHIFT_TYPE);

        return value;
    }

    function allocateObject() private returns (uint256) {
        (uint256 head, uint256 tail) = decodeQueue(unallocatedObjects);

        if (head == NULL_REF) {
            return NULL_REF;
        }

        if (head == tail) {
            unallocatedPages = encodeQueue(0, NULL_REF, NULL_REF, FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL);
        } else {
            unallocatedPages = encodeQueue(0, decodeNodeNext(objects[head]), tail, FLAG_QUEUE_HEAD | FLAG_QUEUE_TAIL);
        }

        return head;
    }

    function createThread(bytes32[] memory data) private {
        uint256 postID = allocateObject();
        require(postID != NULL_REF);

        uint256 threadID = allocateObject();
        require(threadID != NULL_REF);

        objects[threadID] = encodeThread(
            0,
            NULL_REF,
            NULL_REF,
            NULL_REF,
            NULL_REF,
            postID,
            postID,
            1,
            0,
            FLAG_THREAD_NEXT       |
            FLAG_THREAD_PREV       |
            FLAG_THREAD_PAGES_HEAD |
            FLAG_THREAD_PAGES_TAIL |
            FLAG_THREAD_POSTS_HEAD |
            FLAG_THREAD_POSTS_TAIL |
            FLAG_THREAD_COUNT      |
            FLAG_THREAD_OFFSET
        );

        objects[postID] = encodePost(
            0,
            NULL_REF,
            msg.sender,
            NULL_REF,
            0,
            0,
            FLAG_POST_NEXT   |
            FLAG_POST_AUTHOR |
            FLAG_POST_PAGE   |
            FLAG_POST_OFFSET |
            FLAG_POST_LENGTH
        );
    }
}