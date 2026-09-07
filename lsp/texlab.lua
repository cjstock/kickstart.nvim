return {
  cmd = { 'texlab' },
  filetypes = { 'tex', 'plaintex', 'bib' },
  root_markers = { '.git', '.latexmkrc', 'latexmkrc', 'Tectonic.toml' },
  settings = {
    texlab = {
      bibtexFormatter = 'texlab',
      formatterLineLength = 80,
      forwardSearch = {
        executable = 'zathura',
        args = { '--synctex-forward', '%l:1:%f', '%p' },
      },
    },
  },
}
