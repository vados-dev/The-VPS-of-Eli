# eli
export ELI_HOME="/root/.eli"
case ":$PATH:" in
  *":$ELI_HOME:$ELI_HOME/bin:"*) ;;
  *) export PATH="$ELI_HOME:$ELI_HOME/bin:$PATH" ;;
esac
alias eli="eli-exec.sh"
# eli end
