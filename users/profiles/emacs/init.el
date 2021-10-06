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

;; default font
(set-face-attribute 'default nil
                    :family "Sarasa Mono Slab SC"
                    :height 100
                    :weight 'normal
                    :width 'normal)

;; no tabs
(setq-default indent-tabs-mode nil)

;; windmove
(windmove-default-keybindings)

;; split thresholds
(setq split-height-threshold 120
      split-width-threshold 120)

;; quoted char radix
(setq read-quoted-char-radix 16)

;; open init.el command
(defun open-dotfiles ()
  "Open dotfiles"
  (find-file "~/Source/dotfiles"))
(defun open-init-el ()
  "Open init.el file"
  (interactive)
  (find-file "~/Source/dotfiles/users/profiles/emacs/init.el"))
(defun nixos-rebuild-switch ()
  "NixOS rebuild"
  (interactive)
  (async-shell-command "sudo nixos-rebuild --flake ~/Source/dotfiles switch"))
(defun restart-emacs-daemon ()
  "Restart emacs"
  (interactive)
  (async-shell-command "systemctl --user restart emacs"))

;; packages
(require 'package)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)

(use-package ace-window
  :ensure t
  :bind (("M-o" . ace-window)))

(use-package avy
  :ensure t
  :config
  (global-set-key (kbd "C-:") 'avy-goto-char-timer))

(use-package cmake-mode
  :ensure t)

(use-package company
  :ensure t
  :hook ((after-init . global-company-mode)))

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

(use-package fish-mode
  :ensure t)

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
    :hook (org-mode . (lambda () (org-bullets-mode 1))))
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 1.5))
  :bind (("C-c o l" . org-store-link)
         ("C-c o a" . org-agenda)
         ("C-c o c" . org-capture)))

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory (file-truename "~/Source/org-roam"))
  (org-roam-complete-everywhere t)
  (org-roam-capture-templates
   (let ((file-format "%<%Y%m%d%H%M%S>-${slug}.org"))
     `(("d" "default" plain "%?"
        :target (file+head ,file-format "#+title: ${title}")
        :unnarrowed t)
       ("p" "paper" plain (file "~/Source/org-roam/templates/paper.org")
        :target (file+head ,file-format "#+title: ${title}\n#+filetags: Paper")
        :unnarrowed t))))
  :init
  (setq org-roam-v2-ack t)
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ;; Dailies
         ("C-c n j" . org-roam-dailies-capture-today)
         :map org-mode-map
         ("C-M-i"   . completion-at-point))
  :config
  (org-roam-db-autosync-mode))

(use-package paredit
  :ensure t)

(use-package proof-general
  :ensure t
  :config
  (setq proof-three-window-enable t)
  (setq proof-three-window-mode-policy 'hybrid))

(use-package pdf-tools
  :ensure t
  :config
  (pdf-tools-install)
  (setq doc-view-resolution 300
        pdf-view-use-scaling t))

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
  (setq pyim-page-tooltip 'popup)
  (setq pyim-default-scheme 'quanpin)
  (setq pyim-page-length 5)
  (setq-default pyim-english-input-switch-functions
                '(pyim-probe-dynamic-english
                  pyim-probe-isearch-mode
                  pyim-probe-program-mode
                  pyim-probe-org-structure-template))
  (setq-default pyim-punctuation-half-width-functions
                '(pyim-probe-punctuation-line-beginning
                  pyim-probe-punctuation-after-punctuation))
  (pyim-isearch-mode 1)
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

(use-package rainbow-delimiters
  :ensure t)

(use-package rust-mode
  :ensure t)

(use-package scribble-mode
  :ensure t)

(use-package sudo-edit
  :ensure t)

(use-package swift-mode
  :ensure t)

(use-package tex
  :defer t
  :ensure auctex
  :config
  (setq TeX-view-program-selection '((output-pdf "PDF Tools")))
  (setq TeX-source-correlate-start-server t)
  (setq TeX-source-correlate-mode t)
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))

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
