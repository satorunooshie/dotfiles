# github.com/satorunooshie/dotfiles [![startuptime](https://img.shields.io/endpoint?url=https%3A%2F%2Fgist.githubusercontent.com%2Fsatorunooshie%2F23f13f7ddec85107fb2357f08f03ab1e%2Fraw%2Fvim-startuptime.json)](https://github.com/satorunooshie/dotfiles/actions/workflows/vim-startuptime.yml?query=branch%3Amain)
Vim configuration files, maintained for macOS.

Includes a custom color scheme and plugin setup using Vim's native package system.

📄 [View the latest Vim startup time report](https://gist.github.com/satorunooshie/23f13f7ddec85107fb2357f08f03ab1e)

---

## Installation
```bash
# Install plugins and the color scheme.
vim -c 'call InstallPackPlugins()' -c 'sleep 10' -c 'quitall!'
```

Requirements:
- Vim 9 or later
- Built with `+packages` support

## Maintenance
```bash
vim -c 'call UpdatePackPlugins()' -c 'sleep 5' -c 'quitall!'
```

---

## Startup Time Benchmarking
Startup time is measured using [vim-startuptime](https://github.com/rhysd/vim-startuptime), automatically run via GitHub Actions on every push to main.

Benchmark results are published as a badge (top of this page) and as Markdown reports in the [Gist](https://gist.github.com/satorunooshie/23f13f7ddec85107fb2357f08f03ab1e).

---

## Directory Structure

```bash
.
├── .vimrc                   # Vim configuration
├── colors/
│   └── pairs.vim            # Custom color scheme
├── pack/
│   └── ...                  # Plugins (native package structure)
```

---

## Notes

- Plugins are managed using Vim’s built-in `:packadd` system.
- No external plugin manager is used.
- The colorscheme is [pairscolorscheme](https://github.com/satorunooshie/pairscolorscheme), a custom theme maintained in a separate repository.
- Configuration is tested primarily on macOS.
