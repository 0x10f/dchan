// Memory
// ------
// Memory needs to be pre-allocated for use by the forum. Memory is allocated into pages, with each page being the
// maximum size that a post can occupy. A post must be aligned to just one page meaning that a post cannot occupy
// two or more pages. This is to simplify allocating memory for posts by removing any possibility of fragmentation.
contract Forum {
    mapping(uint256 => Slab) slabs;

    struct Slab {

    }
}