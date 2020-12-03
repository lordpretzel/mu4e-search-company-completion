;;; mu4e-search-company-completion.el --- company completion in mu4e search -*- lexical-binding: t -*-

;; Author: Boris Glavic <lordpretzel@gmail.com>
;; Maintainer: Boris Glavic <lordpretzel@gmail.com>
;; Version: 0.1
;; Package-Requires: ((advice-tools "0.1") (company "0.9.13") (counsel-mu4e-and-bbdb-addresses "0.1") (dash "2.12") (mu4e-query-fragments "20200913.1558") (sidewindow-tools "0.1"))
;; Homepage: https://github.com/lordpretzel/mu4e-search-company-completion
;; Keywords:


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Have company completion in mu4e search

;;; Code:

;; ********************************************************************************
;; IMPORTS
(require 'cl-lib)
(require 'company)
(require 'sidewindow-tools)
(require 'advice-tools)
(require 'mu4e)
(require 'mu4e-query-fragments)
(require 'dash)
(require 'counsel-mu4e-and-bbdb-addresses)

;; ********************************************************************************
;; CUSTOM


;; ********************************************************************************
;; VARIABLES
(defvar mu4e-email-completion-match
  nil
  "Store completion matches for mu4e search completion.")

(defvar mu4e-search-company-completion-mu4e-query-fragment-company-candidates
  nil
  "Company completion candidates for mu4e-query-fragments.")

(defvar mu4e-search-company-completion-mu4e-email-completion-prefix
  nil
  "Store completion prefix for mu4e search completion.")

(defvar mu4e-search-company-completion-contacts
  nil
  "List of contacts used for completion.")

;; ********************************************************************************
;; CONSTANTS
(defconst mu4e-search-company-completion-mu-query-keywords-help
  '(
    (:key "cc" :shortcut "c" :help "Cc (carbon-copy) recipient(s)")
    (:key "bcc" :shortcut "h" :help "Bcc (blind-carbon-copy) recipient(s)")
    (:key "from" :shortcut "f" :help "Message sender")
    (:key "to" :shortcut "t" :help "To: recipient(s)")
    (:key "subject" :shortcut "s" :help "Message subject")
    (:key "body" :shortcut "b" :help "Message body")
    (:key "maildir" :shortcut "m" :help "Maildir")
    (:key "msgid" :shortcut "i" :help "Message-ID")
    (:key "prio" :shortcut "p" :help "Message priority" :opions ((:key "low")
                                                                 (:key "normal")
                                                                 (:key "high")))
    (:key "flag" :shortcut "g" :help "Message Flags" :options ((:shortcut "d" :key "draft" :help "Draft Message")
                                                               (:shortcut "f" :key "flagged" :help "Flagged")
                                                               (:shortcut "n" :key "new" :help "New message (in new/ Maildir)")
                                                               (:shortcut "p" :key "passed" :help "Passed ('Handled')")
                                                               (:shortcut "r" :key "replied" :help "Replied")
                                                               (:shortcut "s" :key "seen" :help "Seen")
                                                               (:shortcut "t" :key "trashed" :help "Marked for deletion")
                                                               (:shortcut "a" :key "attach" :help "Has attachment")
                                                               (:shortcut "z" :key "signed" :help "Signed message")
                                                               (:shortcut "x" :key "encrypted" :help "Encrypted message")
                                                               (:shortcut "l" :key "list" :help "Mailing-list message")))
    (:key "date" :shortcut "d" :help "Date range")
    (:key "size" :shortcut "z" :help "Message size range")
    (:key "embed" :shortcut "e" :help "Search inside embedded text parts")
    (:key "file" :shortcut "j" :help "Attachment filename")
    (:key "mime" :shortcut "y" :help "MIME-type of one or more message parts")
    (:key "tag" :shortcut "x" :help "Tags for the message")
    (:key "list" :shortcut "v" :help "Mailing list (the List-Id value)"))
  "Help for mu query keywords.")

;; store list of string that mu query keywords for autocompletion.
(defconst mu4e-search-company-completion-mu4e-query-keywords
  (append
   (mapcar (lambda (k) (concat (plist-get k :key) ":")) mu4e-search-company-completion-mu-query-keywords-help)
   (mapcar (lambda (k) (concat (plist-get k :shortcut) ":")) mu4e-search-company-completion-mu-query-keywords-help))
  "List of string that are mu query keywords for autocompletion.")

;; storing query fragment help
(defconst mu4e-search-company-completion-mu4e-query-fragment-help-buffer
  "*mu4e-query-fragment-help-buffer*")

;; ********************************************************************************
;; FUNCTIONS
(defun mu4e-search-company-completion-mu4e-query-fragments-help (&optional fragment)
  "Show the query corresponding to FRAGMENT.  Also show mu query keywords."
  (interactive)
  (let* ((fragmenthelp (if fragment
                           (concat
                            (propertize fragment 'face '(:foreground "red" :height 0.8))
                            (propertize " := " 'face '(:height 0.8))
                            (propertize (assoc fragment mu4e-query-fragments-list) 'face '(:height 0.8))
                            )
                         (mapconcat (lambda (x) (concat
                                                 (propertize (car x) 'face '(:foreground "red" :height 0.8))
                                                 (propertize " := " 'face '(:height 0.8))
                                                 (propertize (cdr x) 'face '(:height 0.8))))
                                    mu4e-query-fragments-list "\n")))
         (muhelp (mapconcat (lambda (x) (concat (propertize (plist-get x :key) 'face '(:foreground "red" :height 0.8)) " [" (propertize (plist-get x :shortcut) 'face '(:foreground "red" :height 0.8)) "] - " (plist-get x :help))) mu4e-search-company-completion-mu-query-keywords-help "\n")))
    (concat muhelp "\n\n" fragmenthelp)))

(defun mu4e-search-company-completion-mu4e-show-hide-query-fragment-help-posframe (&optional hide)
  "Show or hide (if HIDE is non-nil) posframe showing mu4e query fragment information (which fragments correspond to which queries."
  (interactive "P")
  (let ((help-buffer (get-buffer mu4e-search-company-completion-mu4e-query-fragment-help-buffer)))
    (message "mu4e query help window do hide? %s" (if hide "hide" "show"))
    ;; buffer does already
    (if help-buffer
        (if hide
            (mapc 'delete-window (get-buffer-window-list help-buffer))
          (sidewindow-tools/assign-buffer-to-side-window help-buffer 'left 0 0.5 nil t t))
      ;; buffer does not yet exist
      (unless hide
        (setq help-buffer (get-buffer-create mu4e-search-company-completion-mu4e-query-fragment-help-buffer))
        (let ((helpstr (mu4e-search-company-completion-mu4e-query-fragments-help)))
          ;; create buffer
          (with-current-buffer help-buffer
            (insert helpstr))
          (sidewindow-tools/assign-buffer-to-side-window help-buffer 'left 0 0.5 nil t t))))))

(defun mu4e-search-company-completion-mu4e-query-fragements-create-completion-candidates ()
  "Create mu4e query fragments completion candidates."
  (setq mu4e-search-company-completion-mu4e-query-fragment-company-candidates
        (mapcar (lambda (f)
                  (propertize (car f) :query (cdr f)))
                mu4e-query-fragments-list)))

(defun mu4e-search-company-completion-mu4e-query-fragment-candidate-get-query (s)
  "Return query for a mu4e-query-fragments shortcut S."
  (format " [%s]" (get-text-property 0 :query s)))

(defun mu4e-search-company-completion-mu4e-query-fragment-backend (command &optional arg &rest ignored)
  "Company backend that completes mu4e-query-fragments shortcuts.
Given COMMAND and ARG, remainder is IGNORED."
  (interactive (list 'ia))
  ;;(message "COMPANY: command %s arg: %s" command arg)
  (cl-case command
    (ia (company-begin-backend 'mu4e-search-company-completion-mu4e-query-fragment-backend))
    (prefix (company-grab-symbol-cons "%" 1))
    (candidates
     (cl-remove-if-not
      (lambda (c) (string-prefix-p arg c))
      (mu4e-search-company-completion-mu4e-query-fragements-create-completion-candidates)))
    (annotation (mu4e-search-company-completion-mu4e-query-fragment-candidate-get-query arg))))

;; company backend for mu4e email addresses
(defun mu4e-search-company-completion-company-mu4e-email-postprocess (candidate)
  "Extract email address from completion CANDIDATE."
  ;;(message "prefix <%s> cand: <%s>" mu4e-search-company-completion-mu4e-email-completion-prefix candidate)
  (let ((prefix mu4e-search-company-completion-mu4e-email-completion-prefix)
        (modcand candidate)
        )
    (if prefix
        (progn
          (save-match-data
            (when (string-match "<\\([^>]+\\)>" candidate)
              (setq mu4e-email-completion-match (match-string 1 candidate))
              (setq modcand mu4e-email-completion-match)))
          (delete-region (- (point) (length candidate)) (point))
          (insert prefix)
          (insert modcand)
          ;;(message "%s" mu4e-email-completion-match)
          ;;(message "%s" candidate)
          )))
  (setq mu4e-search-company-completion-mu4e-email-completion-prefix nil))

;; fetch information for a keyword
(defun mu4e-search-company-completion-mu4e-keyword-help-get (key)
  "Return help for mu-query-keyword KEY."
  (let ((el (seq-filter (lambda (x)
                          (or (string-equal (plist-get x :key) key)
                              (string-equal (plist-get x :shortcut) key)))
                        mu4e-search-company-completion-mu-query-keywords-help)))
    (if el
        (car el)
      nil)))

;; generate completion candidates for mu4e company backend
(defun mu4e-search-company-completion-mu4e-query-completion-generate-candidates (arg)
  "Given string ARG to complete, generate candidates and store prefix until column (the mu keyword).  If string does not contain column try to complete the keyword.  If there is a colon provide appropriate completion based on the keyword."
  ;;(message "%s" (concat ">>>" arg "<<<"))
  (if (not (eq (string-match-p "[^:]*$" arg) 0))
      ;; have keyword, determine completion based on keyword
      (let* ((prefix (substring arg 0 (string-match-p "[^:]*$" arg)))
             (suffix (substring arg (string-match-p "[^:]*$" arg))))
        (setq mu4e-search-company-completion-mu4e-email-completion-prefix prefix)
        (pcase prefix
          ;; an address field -> complete with mu4e email address completion
          (`,(or "from:" "f:" "to:" "t:" "cc:" "c:")
             (--filter (cl-search suffix it) mu4e-search-company-completion-contacts))
          ;; flag
          (`,(or "flag:" "g:")
           (let* ((flagshelp (plist-get (mu4e-search-company-completion-mu4e-keyword-help-get "flag") :options))
                  (flags (append (mapcar (lambda (x) (plist-get x :key)) flagshelp))))
             ;;(message "flag-complete <%s> for flags <%s>" suffix (mapconcat 'identity fslags " "))
             (all-completions suffix flags)))))
    ;; no keyword yet, try to complete keyword
    (let* ((keywords mu4e-search-company-completion-mu4e-query-keywords))
      (seq-filter (lambda (x) (string-prefix-p arg x)) keywords))))

;; generate an annotation (the name of the person mapped to the email address
(defun mu4e-search-company-completion-mu4e-query-completion-generate-annotation (s)
  "Generate an annotation the name of the person for email address S."
  (let* ((email (get-text-property 0 :email s)))
         (format " [%s]" email)))

;; function that grabs non-space text before point
(defun mu4e-search-company-completion-company-grab-symbol-greedy ()
  "Find prefix to complete."
  (when (looking-back "[^[:space:]]+" nil t)
    (or (match-string-no-properties 0) "")))

;; company backend for email addresses
(defun mu4e-search-company-completion-mu4e-email-addresses-backend (command &optional arg &rest ignored)
  "Company backend that completes mu4e-query-fragments shortcuts.  Given COMMAND and ARG dispatch to the right function.  Remaining arguments are IGNORED."
  ;;(smessage "query backend: command %s arg: %s" command arg)
  (interactive (list 'ia))
  (cl-case command
    (ia (company-begin-backend 'mu4e-search-company-completion-mu4e-email-addresses-backend))
    (prefix (mu4e-search-company-completion-company-grab-symbol-greedy))
    (candidates (mu4e-search-company-completion-mu4e-query-completion-generate-candidates arg))
    (annotation (mu4e-search-company-completion-mu4e-query-completion-generate-annotation arg))
    (post-completion (mu4e-search-company-completion-company-mu4e-email-postprocess arg))))

;; Custom Minor Mode
(define-minor-mode mu4e-query-completion-mode
  "When activated <tab> calls company-complete"
  ;; The initial value - Set to 1 to enable by default
  nil
  ;; The indicator for the mode line.
  " QueryCompletion"
  ;; The minor mode keymap
  `((,(kbd "<tab>") . company-complete))
  ;; Make mode global rather than buffer local
  :global 1
  ;; customization group
  :group 'mu4e-search-company-completion)

;; hook for setting right company backend in mu4e search
(defun mu4e-search-company-completion-mu4e-search-hook ()
  "Setup stuff for mu4e search including query-fragment autocompletion."
  (company-mode 1)
  (setq-local company-backends
              '((mu4e-search-company-completion-mu4e-email-addresses-backend
                 mu4e-search-company-completion-mu4e-query-fragment-backend)))
  (setq-local company-minimum-prefix-length 1)
  (mu4e~compose-setup-completion)
  (mu4e-query-completion-mode 1))

;; hook that removes mu4e minibuffer-setup hooks for search (e.g., cleanup after C-g)
(defun mu4e-search-company-completion-mu4e-search-minibuffer-quit-hook ()
  "remove hooks from minibuffer-setup-hook after user quits mu4e-headers-search."
  (message "in quit hook!")
  ;;(company-mode 0)
  (mu4e-query-completion-mode -1)
  (remove-hook 'minibuffer-setup-hook 'mu4e-search-company-completion-mu4e-search-hook)
  (remove-hook 'minibuffer-exit-hook 'mu4e-search-company-completion-mu4e-search-minibuffer-quit-hook)
  (mu4e-search-company-completion-mu4e-show-hide-query-fragment-help-posframe t))

;; replacement for mu4e-headers-search that activates company completion
(defun mu4e-search-company-completion-mu4e-headers-search (&optional expr prompt edit
                                      ignore-history msgid show)
  "Search in the mu database for EXPR, and switch to the output
            buffer for the results. This is an interactive function which ask
            user for EXPR. PROMPT, if non-nil, is the prompt used by this
            function (default is \"Search for:\"). If EDIT is non-nil,
            instead of executing the query for EXPR, let the user edit the
            query before executing it. If IGNORE-HISTORY is true, do *not*
            update the query history stack. If MSGID is non-nil, attempt to
            move point to the first message with that message-id after
            searching. If SHOW is non-nil, show the message with MSGID."
  ;; note: we don't want to update the history if this query comes from
  ;; `mu4e~headers-query-next' or `mu4e~headers-query-prev'."
  (interactive)
  (let* ((prompt (mu4e-format (or prompt "Search for: ")))
         (sexpr expr))
    ;; read query from minibuffer with completion if not provided
    (when (or edit (not sexpr))
      (add-hook 'minibuffer-exit-hook #'mu4e-search-company-completion-mu4e-search-minibuffer-quit-hook)
      (mu4e-search-company-completion-mu4e-show-hide-query-fragment-help-posframe)
      (minibuffer-with-setup-hook 'mu4e-search-company-completion-mu4e-search-hook
        (setq sexpr (if edit
                        (read-string prompt expr)
                      (read-string prompt nil 'mu4e~headers-search-hist)))))
    ;; handle query
    (mu4e-search-company-completion-mu4e-show-hide-query-fragment-help-posframe t)
    (mu4e-mark-handle-when-leaving)
    (mu4e~headers-search-execute sexpr ignore-history)
    (setq mu4e~headers-msgid-target msgid
          mu4e~headers-view-target show)))

(defun mu4e-search-company-completion-mu4e-headers-search-narrow (filter)
  "Narrow the last search by appending search expression FILTER to the last search expression.  Note that you can go back to previous query (effectively, 'widen' it), with `mu4e-headers-query-prev'."
  (interactive
   (let ((filter))
     (add-hook 'minibuffer-exit-hook #'mu4e-search-company-completion-mu4e-search-minibuffer-quit-hook)
     (mu4e-search-company-completion-mu4e-show-hide-query-fragment-help-posframe)
     (minibuffer-with-setup-hook 'mu4e-search-company-completion-mu4e-search-hook
       (setq filter (read-string (mu4e-format "Narrow down to: ")
                                 nil 'mu4e~headers-search-hist nil t)))
     (list filter)))
  (unless mu4e~headers-last-query
    (mu4e-warn "There's nothing to filter"))
  (mu4e-headers-search
   (format "(%s) AND (%s)" mu4e~headers-last-query filter)))

;; setup `mu4e-search-company-completion' to by advising mu4e functions
;;;###autoload
(defun mu4e-search-company-completion-setup ()
  "Setup `mu4e-search-company-completion' to by advising mu4e functions."
  (interactive)
  (advice-tools/advice-add-if-def
   'mu4e-headers-search-narrow
   :override
   'mu4e-search-company-completion-mu4e-headers-search-narrow)
  (advice-tools/advice-add-if-def
   'mu4e-headers-search
   :override
   'mu4e-search-company-completion-mu4e-headers-search)
  (when (not mu4e-search-company-completion-contacts)
    (setq mu4e-search-company-completion-contacts (counsel-mu4e-and-bbdb-full-contacts-sorted)))
  (mu4e-search-company-completion-mu4e-query-fragements-create-completion-candidates))

;;;###autoload
(defun mu4e-search-company-completion-remove ()
  "Unadvise `mu4e' functions."
  (interactive)
  (advice-tools/advice-remove-if-def
   'mu4e-headers-search-narrow
   'mu4e-search-company-completion-mu4e-headers-search-narrow)
  (advice-tools/advice-remove-if-def
   'mu4e-headers-search
   'mu4e-search-company-completion-mu4e-headers-search))

(provide 'mu4e-search-company-completion)
;;; mu4e-search-company-completion.el ends here
