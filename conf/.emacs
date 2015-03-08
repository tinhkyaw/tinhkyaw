(autoload 'inquir "inquir" "The inquir front-end" t)'

;;; stop creating backup files
(setq make-backup-files nil)

;;; stop creating autosave files
(setq auto-save-default nil)

;;; don't truncate lines
(set-default 'truncate-lines nil)

;;; don't truncate lines in partial window
(set-default 'truncate-partial-width-windows nil)

;;; Allow extra space at the end of the line
(setq-default fill-column 74)

;;; Example of setting a variable
;;; This particular example causes the current line number to be shown
;;; Remove the ; in front to turn this feature on.
(setq-default line-number-mode t)

;;; Example of binding a key
;;; This particular example binds "ESC =" to the "goto-line" function.
;;; Remove the ; in front to turn this feature on.
;; (global-set-key "\M-="  'goto-line)

;; make marked region visible
(if (boundp 'transient-mark-mode)
    (setq transient-mark-mode t))
(setq mark-even-if-inactive t)

;; Scroll only 1 line
(setq scroll-step 1)
(custom-set-variables
 '(frame-background-mode nil))
(custom-set-faces)

;; Set up the keyboard so the delete key on both the regular keyboard
;; and the keypad delete the character under the cursor and to the right
;; under X, instead of the default, backspace behavior.
(global-set-key [delete] 'delete-char)
(global-set-key [kp-delete] 'delete-char)

(set-default-font "*-courier-medium-r-*-*-*-140-*")

(display-time)

;; can replace selected text with typing
(delete-selection-mode t)

(put 'downcase-region 'disabled nil)


;; ===== Set standard indent to 2 rather that 4 ====
(setq standard-indent 2)


;; ===== Turn off tab character =====

;;
;; Emacs normally uses both tabs and spaces to indent lines. If you
;; prefer, all indentation can be made from spaces only. To request this,
;; set `indent-tabs-mode' to `nil'. This is a per-buffer variable;
;; altering the variable affects only the current buffer, but it can be
;; disabled for all buffers.

;;
;; Use (setq ...) to set value locally to a buffer
;; Use (setq-default ...) to set value globally
;;
(setq-default indent-tabs-mode nil)

;; ===== Turn on Auto Fill mode automatically in all modes =====

;; Auto-fill-mode the the automatic wrapping of lines and insertion of
;; newlines when the cursor goes over the column limit.

;; This should actually turn on auto-fill-mode by default in all major
;; modes. The other way to do this is to turn on the fill for specific modes
;; via hooks.

(setq auto-fill-mode 1)

;; load packages
(load "~/.emacs.d/my-loadpackages.el")
