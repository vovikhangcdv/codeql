import java
import semmle.code.java.dataflow.FlowSources

/** A sink for JShell expression injection vulnerabilities. */
class JShellInjectionSink extends DataFlow::Node {
  JShellInjectionSink() {
    this.asExpr() = any(JShellEvalCall jsec).getArgument(0)
    or
    this.asExpr() = any(SourceCodeAnalysisWrappersCall scawc).getArgument(0)
    or
    exists(MethodAccess ma |
      ma.getMethod().hasName("source") and
      ma.getMethod().getNumberOfParameters() = 0 and
      ma.getMethod()
          .getDeclaringType()
          .getASupertype*()
          .hasQualifiedName("jdk.jshell", "SourceCodeAnalysis$CompletionInfo") and
      ma.getQualifier() = this.asExpr() and
      (
        ma = any(JShellEvalCall jsec).getArgument(0)
        or
        ma = any(SourceCodeAnalysisWrappersCall scawc).getArgument(0)
      )
    )
  }
}

/** A call to `JShell.eval`. */
class JShellEvalCall extends MethodAccess {
  JShellEvalCall() {
    this.getMethod().hasName("eval") and
    this.getMethod().getDeclaringType().hasQualifiedName("jdk.jshell", "JShell") and
    this.getMethod().getNumberOfParameters() = 1
  }
}

/** A call to `SourceCodeAnalysis.wrappers`. */
class SourceCodeAnalysisWrappersCall extends MethodAccess {
  SourceCodeAnalysisWrappersCall() {
    this.getMethod().hasName("wrappers") and
    this.getMethod().getDeclaringType().hasQualifiedName("jdk.jshell", "SourceCodeAnalysis") and
    this.getMethod().getNumberOfParameters() = 1
  }
}
