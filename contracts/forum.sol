pragma solidity ^0.4.0;

// Linking
// -------
// Linking is a standard for writing links to other posts that are contained within the forum.
//
// Tipping
// -------
// Tipping is a standard for sending token to authors of posts.
//
contract Forum {
    // Threads is all of the threads that are contained within the forum. Threads are
    // mapped by their identifier which is the identifier of the first post in the
    // thread. See the Thread documentation for more information.
    mapping(uint256 => Thread) threads;

    // Posts is all of the posts that are contained within the forum. Posts are mapped
    // by their identifier which is determined from a hash of the fields. See the
    // Post documentation for more information.
    mapping(uint256 => Fragment) fragments;

    // Nonce is the highest known nonce that was sent to the network for an address. It
    // is meant for bookkeeping purposes when creating new posts. If a nonce is not
    // present in this mapping then the user has not made a post yet. The nonce
    // should not be used as a way to determine how many posts a specific address
    // has made because a user may specify any nonce for a post as long as it has
    // not been used before.
    //
    // When a post is successfully published the nonce *must* be updated if it greater
    // than the currently recorded nonce.
    mapping(address => uint256) nonces;

    // SymbolEncoding is the huffman tree which is used to decode and encode posts that are stored
    // in the contract. This field is set when the contract is constructed and cannot be
    // changed once it is initialized.
    byte[] symbolEncoding;

    // Parsers are mapped by the hash of the author and nonce of the post chain. This guarantees
    // each post chain has their own parser state.
    //
    // id := keccak(post.author, post.nonce)
    mapping(uint256 => ParserState) parsers;

    // Thread is a structure used to describe a sequence of posts. The identifier for a thread is
    // the same as its identifier of the first post.
    struct Thread {
        // The identifiers of all the submitted post chains that are apart of the thread
        // in ascending order of the time it was appended to the thread. The identifier
        // will always refer to the tail of the post chain. This is a mechanism of the
        // tail only being written to the thread when all of the ancestors have been
        // published.
        mapping(uint256 => uint256) posts;

        // Look is a reverse lookup table which maps submission ids to its index in the thread.
        // It is to be used for locality queries where a rendering engine may want to grab
        // the 'nearest' submissions.
        mapping(uint256 => uint256) lookup;

        // Counter is used for assigning a local identifier to appended submissions.
        // Each time a new submission is appended to the thread this field is
        // incremented by one.
        uint256 counter;
    }

    // Identifier
    // ----------
    // The identifier of a post is determinable off-chain even before publishing
    // the post on-chain. This allows posts to have a universally unique identifier
    // that is dependant on: the author, the parent, the child, the contents, and
    // the nonce. The identifier is calculated as follows:
    //
    // id = keccak(post.author, post.thread, post.parent, post.child, post.contents, post.nonce)
    //
    // The parent and child are included to stop 'piggy backing'. Suppose a post
    // chain is published and at a future time someone publishes a post that
    // reuses a post in the chain that is neither the head or tail. If the
    // child and parent were not present it would be possible to extend (fork)
    // peoples posts, but because to publish a post the post must be the child
    // of the parent this is not possible in this implementation.
    //
    // Because identifiers are universally unique if two posts share the same
    // identifier they are considered equivalent.
    //
    // Chains
    // ------
    // Posts an optionally doubly linked list structure which allows for single
    // longer submissions to be published. It is assumed if a post is an ancestor
    // or descendant of one another they belong to the same submission.
    //
    // This is designed this way to break apart the unit of work of what it takes
    // to publish a submission.
    //
    // Publishing
    // ----------
    // To be successfully published:
    // - The post must not already exist (two posts cannot have the same ID).
    // - When the post is not the head of the chain, its parent must exist and the parents child must be the post.
    // - In addition to the previous condition, the parents thread must be the same.
    // - The contents must meet the required standards.
    //
    // There is an additional requirement for delegated publishing that the
    // signature must be valid for the post.
    struct Fragment {
        // Author is the address who published the post.
        address author;

        // Thread is the identifier of the thread that the post belongs to.
        // When this value is zero then this post is the head or first post of the thread.
        uint256 thread;

        // Parent is the previous post in the chain. When this value is zero then this post is the head of the chain.
        uint256 parent;

        // Child is the next post in the chain. When this value is zero then this post is the tail of the chain.
        uint256 child;

        // The text contents of the post.
        bytes32 contents;

        // Nonce is a incremental value per address which is used to help distinguish posts
        // made by the same address. Essentially it provides a way to differentiate posts
        // that have the same fields.
        uint256 nonce;
    }

    struct ParserState {
        // Index is the current index in the huffman tree. This is used when symbols in a fragment's content
        // are on byte boundaries, for example when a symbol may be half encoded in the first fragment at
        // the end of the contents but the remainder of the bits are the start of the second fragment.
        uint256 index;
    }

    // GetHead returns the fragment which is the head of a post chain. If the head cannot
    // be determined then this function returns 0.
    function getPostHead(uint256 fragmentID) view returns (uint256) {
        return 0;
    }

    // GetTail returns the fragment which is the tail of a post chain. If the tail cannot
    // be determined then this function returns 0.
    function getPostTail(uint256 fragmentID) view returns (uint256) {
        return 0;
    }
}