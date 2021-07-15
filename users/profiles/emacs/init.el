(message "Start loading init.el")


(defvar host-dir "~/.emacs.d/host/")
(if (file-exists-p host-dir)
    (progn
      (message "Start loading host init")
      (add-to-list 'load-path host-dir)
      (require 'init-host)
      (message "Finish loading host init"))
  (warn "Host file not found"))

;; customize file
(defvar var-dir (concat user-emacs-directory "var/"))
(make-directory var-dir :parents)
(setq custom-file (concat var-dir "custom.el"))

;; no temporary files
(defvar backup-dir (concat var-dir "backup"))
(defvar auto-save-dir (concat var-dir "auto-save/"))
(make-directory backup-dir :parents)
(make-directory auto-save-dir :parents)
(setq backup-directory-alist
      `(("." . ,backup-dir)))
(setq auto-save-file-name-transforms
      `((".*" ,auto-save-dir t)))
(setq create-lockfiles nil)

;; no menu bar
(menu-bar-mode -1)
;; no tool bar
(tool-bar-mode -1)

(setq package-archives
      '(("gnu" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
        ("melpa" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))

;; no tabs
(setq-default indent-tabs-mode nil)

;; window move
(windmove-default-keybindings)

;; quoted char radix
(setq read-quoted-char-radix 16)

;; recompile all command
(defun recompile-all ()
  "Recompile everything in package user directory"
  (interactive)
  (byte-recompile-directory package-user-dir nil 'force))
;; open init.el command
(defun open-init-el ()
  "Open init.el file"
  (interactive)
  (find-file "~/Source/nixos-configuration/configuration/users/yinfeng/home/dotfiles/emacs.d/init.el"))

;; packages
(require 'package)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)

(use-package auctex
  :ensure t
  :defer t)

(use-package avy
  :ensure t
  :config
  (global-set-key (kbd "C-:") 'avy-goto-char-timer))

(use-package cmake-mode
  :ensure t)

(use-package company
  :ensure t
  :init
  (add-hook 'after-init-hook 'global-company-mode))

(use-package counsel
  :ensure t
  :delight
  :config
  (counsel-mode)
  (use-package ivy
    :ensure t
    :delight
    :config
    (ivy-mode))
  (use-package swiper
    :ensure t
    :config
    (global-set-key (kbd "C-s") 'swiper-isearch)))

(use-package counsel-projectile
  :ensure t
  :config
  (counsel-projectile-mode))

(use-package delight
  :ensure t)

(use-package direnv
  :ensure t
  :config
  (direnv-mode))

(use-package eldoc
  :ensure t)

(use-package expand-region
  :ensure t
  :config
  (global-set-key (kbd "C-=") 'er/expand-region))

(use-package fira-code-mode
  :ensure t
  :delight
  :custom (fira-code-mode-disabled-ligatures '("[]" "x"))
  :hook ((prog-mode . fira-code-mode)))

(use-package flycheck
  :ensure t)

(use-package flycheck-projectile
  :ensure t)

(use-package json-mode
  :ensure t)

(use-package lsp-haskell
  :ensure t
  :config
  (setq lsp-haskell-process-path-hie "haskell-language-server-wrapper"))

(use-package lsp-mode
  :ensure t
  :hook ((lsp-mode . (lambda ()
                       (let ((lsp-keymap-prefix "C-c l"))
                         (lsp-enable-which-key-integration))))
         (haskell-mode . lsp)
         (haskell-literate-mode . lsp)
         (c-mode . lsp)
         (c++-mode . lsp)
         (rust-mode . lsp))
  :config
  (setq lsp-rust-server 'rust-analyzer)
  (define-key lsp-mode-map (kbd "C-c l") lsp-command-map))

(use-package idris-mode
  :ensure t)

(use-package lsp-ui
  :ensure t)

(use-package lua-mode
  :ensure t)

(use-package magit
  :ensure t)

(use-package markdown-mode
  :ensure t)

(use-package neotree
  :ensure t)

(use-package nix-mode
  :ensure t)

(use-package org
  :ensure t
  :config
  (use-package org-roam
    :ensure t
    :config
    (setq org-roam-directory "~/Source/org-roam")
    :init
    (add-hook 'after-init-hook 'org-roam-mode))
  (use-package org-bullets
    :ensure t
    :config
    (setq org-bullets-bullet-list
          '("●"
            "○"
            "✿"
            "❀"
            "◆"
            "◇"))
    :hook
    (org-mode . (lambda () (org-bullets-mode 1))))
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 1.5))
  :bind
  ("C-c l" . org-store-link)
  ("C-c a" . org-agenda)
  ("C-c c" . org-capture))

(use-package paredit
  :ensure t)

(use-package proof-general
  :ensure t
  :config
  (setq proof-three-window-enable t)
  (setq proof-three-window-mode-policy 'hybrid))

(use-package pdf-tools
  :ensure t)

(use-package projectile
  :ensure t
  :delight
  :config
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
  (projectile-mode +1))

(use-package pyim
  :ensure t
  :delight pyim-isearch-mode
  :config
  (setq default-input-method "pyim")
  (setq pyim-default-scheme 'quanpin)
  (setq-default pyim-english-input-switch-functions
                '(pyim-probe-dynamic-english
                  pyim-probe-isearch-mode
                  pyim-probe-program-mode
                  pyim-probe-org-structure-template))
  (setq-default pyim-punctuation-half-width-functions
                '(pyim-probe-punctuation-line-beginning
                  pyim-probe-punctuation-after-punctuation))
  (pyim-isearch-mode 1)
  (use-package posframe
    :ensure t
    :config
    (setq pyim-page-tooltip 'posframe))
  (use-package pyim-basedict
    :ensure t
    :config
    (pyim-basedict-enable))
  (define-key pyim-mode-map "." 'pyim-page-next-page)
  (define-key pyim-mode-map "," 'pyim-page-previous-page)
  :bind
  (("C-|" . pyim-convert-string-at-point)))

(use-package racket-mode
  :ensure t)

(use-package restart-emacs
  :ensure t)

(use-package rust-mode
  :ensure t)

(use-package scribble-mode
  :ensure t)

(use-package sudo-edit
  :ensure t)

(use-package swift-mode
  :ensure t)

(use-package undo-tree
  :ensure t
  :delight
  :config
  (global-undo-tree-mode))

(use-package which-key
  :ensure t
  :delight
  :config
  (which-key-mode))

(use-package yaml-mode
  :ensure t)

(load-file (let ((coding-system-for-read 'utf-8))
             (shell-command-to-string "agda-mode locate")))

(message "Finish loading init.el")
