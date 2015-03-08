; ~/.emacs.d/my-loadpackages.el
; loading package
(load "~/.emacs.d/my-packages.el")

(require 'color-theme)
(color-theme-initialize)
(color-theme-subtle-hacker)

(require 'gradle-mode)
(require 'hive)
(require 'pig-mode)
(require 'scala-mode2)
(require 'sbt-mode)
(require 'thrift)

(add-to-list 'auto-mode-alist '("\\.\\(php\\|inc\\)$" . php-mode))
(autoload 'php-mode "php-mode" "PHP mode." t)

(add-to-list 'auto-mode-alist '("\\.m$" . octave-mode))
