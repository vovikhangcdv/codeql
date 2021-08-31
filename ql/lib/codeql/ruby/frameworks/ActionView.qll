private import codeql.ruby.AST
private import codeql.ruby.Concepts
private import codeql.ruby.controlflow.CfgNodes
private import codeql.ruby.DataFlow
private import codeql.ruby.dataflow.RemoteFlowSources
private import codeql.ruby.ast.internal.Module
private import ActionController

predicate inActionViewContext(AstNode n) {
  // Within a template
  // TODO: n.getLocation().getFile() instanceof ErbFile
  n.getLocation().getFile().getExtension() = "erb"
}

/**
 * A method call on a string to mark it as HTML safe for Rails.
 * Strings marked as such will not be automatically escaped when inserted into
 * HTML.
 */
abstract class HtmlSafeCall extends MethodCall {
  HtmlSafeCall() { this.getMethodName() = "html_safe" }
}

// A call to `html_safe` from within a template or view component.
private class ActionViewHtmlSafeCall extends HtmlSafeCall {
  ActionViewHtmlSafeCall() { inActionViewContext(this) }
}

// A call in a context where some commonly used `ActionView` methods are available.
private class ActionViewContextCall extends MethodCall {
  ActionViewContextCall() {
    this.getReceiver() instanceof Self and
    inActionViewContext(this)
  }

  predicate isInErbFile() {
    // TODO: this.getLocation().getFile() instanceof ErbFile
    this.getLocation().getFile().getExtension() = "erb"
  }
}

/** A call to the `raw` method to output a value without HTML escaping. */
class RawCall extends ActionViewContextCall {
  RawCall() { this.getMethodName() = "raw" }
}

// A call to the `params` method within the context of a template or view component.
private class ActionViewParamsCall extends ActionViewContextCall, ParamsCall { }

/**
 * A call to a `render` method that will populate the response body with the
 * rendered content.
 */
abstract class RenderCall extends MethodCall {
  RenderCall() { this.getMethodName() = "render" }

  private string getWorkingDirectory() {
    result = this.getLocation().getFile().getParentContainer().getAbsolutePath()
  }

  bindingset[templatePath]
  private string templatePathPattern(string templatePath) {
    exists(string basename, string relativeRoot |
      // everything after the final slash, or the whole string if there is no slash
      basename = templatePath.regexpCapture("^(?:.*/)?([^/]*)$", 1) and
      // everything up to and including the final slash
      relativeRoot = templatePath.regexpCapture("^(.*/)?(?:[^/]*?)$", 1)
    |
      (
        // path relative to <source_prefix>/app/views/
        result = "%/app/views/" + relativeRoot + "%" + basename + "%"
        or
        // relative to file containing call
        result = this.getWorkingDirectory() + "%" + templatePath + "%"
      )
    )
  }

  private string getTemplatePathPatterns() {
    exists(string templatePath |
      exists(Expr arg |
        // TODO: support other ways of specifying paths (e.g. `file`)
        arg = this.getKeywordArgument("partial") or
        arg = this.getKeywordArgument("template") or
        arg = this.getKeywordArgument("action") or
        arg = this.getArgument(0)
      |
        templatePath = arg.(StringlikeLiteral).getValueText()
      )
    |
      result = this.templatePathPattern(templatePath)
    )
  }

  /**
   * Get the template file to be rendered by this call, if any.
   */
  // TODO: parameter should be `ErbFile`
  File getTemplateFile() { result.getAbsolutePath().matches(this.getTemplatePathPatterns()) }

  /**
   * Get the local variables passed as context to the renderer
   */
  HashLiteral getLocals() { result = this.getKeywordArgument("locals") }
  // TODO: implicit renders in controller actions
}

// A call to the `render` method within the context of a template or view component.
private class ActionViewRenderCall extends RenderCall, ActionViewContextCall { }

/**
 * A render call that does not automatically set the HTTP response body.
 */
abstract class RenderToCall extends MethodCall {
  RenderToCall() { this.getMethodName() = ["render_to_body", "render_to_string"] }
}

// A call to `render_to` from within a template or view component.
private class ActionViewRenderToCall extends ActionViewContextCall, RenderToCall { }

/**
 * A call to the ActionView `link_to` helper method.
 *
 * This generates an HTML anchor tag. The method is not designed to expect
 * user-input, so provided paths are not automatically HTML escaped.
 */
class LinkToCall extends ActionViewContextCall {
  LinkToCall() { this.getMethodName() = "link_to" }

  // TODO: the path can also be specified through other optional arguments
  Expr getPathArgument() { result = this.getArgument(1) }
}
// TODO: model flow in/out of template files properly,