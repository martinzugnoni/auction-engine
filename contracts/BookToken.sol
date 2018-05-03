pragma solidity ^0.4.2;

import "./SafeMath.sol";
import "./AddressUtils.sol";
import "./ERC721.sol";


contract BookToken is ERC721 {
    /*
     * NFT representing books
     */

    using SafeMath for uint256;
    using AddressUtils for address;

    string public constant name = "Book Token";
    string public constant symbol = "BOOK";

    enum Genre { ScienceFiction, Satire, Drama, Adventure, Romance, Horror }

    struct Book {
        string author;
        string title;
        uint256 publishedAt;
        Genre genre;
    }
    Book[] private books;

    event Mint(uint256 bookIndex, address creator);

    function BookToken() public {
        // mint initial books
        _mintBook(msg.sender, "J. K. Rowling", "Harry Potter and the Philosophers Stone", Genre.ScienceFiction);
        _mintBook(msg.sender, "William Shakespeare", "Hamlet", Genre.Drama);
        _mintBook(msg.sender, "J. R. R. Tolkien", "The Lord of the Rings", Genre.ScienceFiction);
    }

    function _mintBook(address owner, string author, string title, Genre genre) internal returns (uint256) {
        Book memory book = Book({
            author: author,
            title: title,
            publishedAt: now,
            genre: genre
        });
        uint256 index = books.push(book) - 1;
        emit Mint(index, msg.sender);

        addTokenTo(owner, index);
        emit Transfer(address(0), owner, index);

        return index;
    }

    function getTotalBooks() public view returns (uint) { return books.length; }
    function getAuthor(uint256 bookIndex) public view returns (string) { return books[bookIndex].author; }
    function getTitle(uint256 bookIndex) public view returns (string) { return books[bookIndex].title; }
    function getGenre(uint256 bookIndex) public view returns (Genre) { return books[bookIndex].genre; }
}
