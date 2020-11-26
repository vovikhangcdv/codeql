import codeql.Locations
import codeql_ruby.Method
import codeql_ruby.Parameter
private import codeql_ruby.Generated

/**
 * A node in the abstract syntax tree. This class is the base class for all Ruby
 * program elements.
 */
class AstNode extends @ast_node {
  Generated::AstNode generated;

  AstNode() { generated = this }

  /**
   * Gets the name of a primary CodeQL class to which this node belongs.
   *
   * This predicate always has a result. If no primary class can be
   * determined, the result is `"???"`. If multiple primary classes match,
   * this predicate can have multiple results.
   */
  string describeQlClass() { result = "???" }

  /** Gets a textual representation of this node. */
  string toString() { result = "AstNode" }

  /** Gets the location if this node. */
  Location getLocation() { result = generated.getLocation() }

  /**
   * Gets the parent of this node in the abstract syntax tree, if it has one.
   */
  AstNode getParent() { result = generated.getParent() }

  /**
   * Gets the index (position) of this node in the parent node's list of
   * children.
   */
  int getParentIndex() { result = generated.getParentIndex() }
}

/**
 * Models program elements for destructured patterns.
 */
abstract class Pattern extends AstNode {
  /** Gets the number of elements in this pattern. */
  abstract int getNumberOfElements();

  /** Gets the nth element in this pattern. */
  abstract AstNode getElement(int n);

  /** Gets an element in this pattern. */
  AstNode getAnElement() { result = this.getElement(_) }
}
