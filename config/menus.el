;;; menus.el --- -*- lexical-binding: t; -*-
;; menus.el — Transient menus (main, file, buffers, view, settings, pane, apps, here)
;;
;; Contents:
;;   - File menu
;;   - Buffers menu
;;   - View menu
;;   - Settings menu (theme, reload, open config dir)
;;   - Markdown formatting menu
;;   - AsciiDoc formatting menu
;;   - Org formatting menu
;;   - Pane/window menu
;;   - Apps menu (terminal, browser, gemini, IRC submenu)
;;   - Here menus: EWW, Elpher, ERC, Eat (context-sensitive)
;;   - ay-here-menu dispatcher (selects menu by major mode)
;;   - Main menu (ay-menu, bound to C-k)


;; ── File ──────────────────────────────────
(transient-define-prefix ay-file-menu ()
  "File operations."
  [["file"
    ("n" "new (scratch)"  (lambda () (interactive) (switch-to-buffer "*scratch*")))
    ("o" "open"           ay-open-file-dialog)
    ("s" "save"           ay-save-dialog)
    ("S" "save as"        ay-save-as-dialog)
    ("c" "close"          kill-buffer)]])

;; ── Buffers ───────────────────────────────
(transient-define-prefix ay-buffers-menu ()
  "Buffer operations."
  [["buffers"
    ("l" "list"  ivy-switch-buffer)
    ("c" "close" kill-buffer)]])

;; ── View ──────────────────────────────────
(transient-define-prefix ay-view-menu ()
  "View options."
  [["view"
    ("t" "typesetter mode" ay-typewriter-mode)
    ("c" "center mode"     olivetti-mode)
    ("m" "markdown mode"   markdown-mode)
    ("a" "asciidoc mode"   adoc-mode)
    ("o" "org mode"        org-mode)
    ("p" "plain text"      text-mode)]])

;; ── Settings ──────────────────────────────
(transient-define-prefix ay-settings-menu ()
  "Settings."
  [["settings"
    ("t" "theme"         ay-pick-theme)
    ("r" "reload config" reload-config)
    ("o" "open config"   (lambda () (interactive)
                           (dired (expand-file-name "config/" user-emacs-directory))))]])

;; ── Markdown ──────────────────────────────
(transient-define-prefix ay-markdown-menu ()
  "Markdown formatting, insertion, lists and document actions."
  [["format"
    ("b" "bold"          markdown-insert-bold)
    ("i" "italic"        markdown-insert-italic)
    ("c" "code"          markdown-insert-code)
    ("s" "strikethrough" markdown-insert-strike-through)
    ("q" "quote"         markdown-insert-blockquote)]
   ["insert"
    ("h" "heading"       markdown-insert-header-dwim)
    ("l" "link"          markdown-insert-link)
    ("g" "image"         markdown-insert-image)
    ("k" "code block"    markdown-insert-gfm-code-block)
    ("t" "table"         markdown-insert-table)
    ("f" "footnote"      markdown-insert-footnote)
    ("r" "rule"          markdown-insert-hr)]]
  [["list"
    ("n" "item"          markdown-insert-list-item)
    ("x" "checkbox"      markdown-insert-gfm-checkbox)
    ("<" "promote"       markdown-promote)
    (">" "demote"        markdown-demote)
    ("[" "move up"       markdown-move-up)
    ("]" "move down"     markdown-move-down)
    ("#" "renumber"      markdown-cleanup-list-numbers)]
   ["document"
    ("p" "preview"       ay-preview)
    ("e" "export html"   markdown-export)
    ("a" "fold all"      markdown-shifttab)
    ("d" "show images"   markdown-toggle-inline-images)]])

;; ── AsciiDoc ──────────────────────────────
;; adoc-mode ships commands for the inline styles; the block constructs
;; below have no command of their own, so they are written out here.
(defun ay-adoc--wrap-role (role)
  "Wrap the region, or point, in an AsciiDoc ROLE span: [.ROLE]#text#."
  (if (use-region-p)
      (let ((text (buffer-substring-no-properties
                   (region-beginning) (region-end))))
        (delete-region (region-beginning) (region-end))
        (insert "[." role "]#" text "#"))
    (insert "[." role "]##")
    (backward-char 1)))

(defun ay-adoc-strikethrough ()
  "Strike through the region, or start a struck-through span."
  (interactive)
  (ay-adoc--wrap-role "line-through"))

(defun ay-adoc-underline ()
  "Underline the region, or start an underlined span."
  (interactive)
  (ay-adoc--wrap-role "underline"))

(defun ay-adoc-insert-heading ()
  "Insert a section title one level below the enclosing one."
  (interactive)
  (let ((level 1))
    (save-excursion
      (when (re-search-backward "^\\(=\\{1,5\\}\\) " nil t)
        (setq level (1+ (- (match-end 1) (match-beginning 1))))))
    (unless (bolp) (insert "\n"))
    (insert (make-string level ?=) " ")))

(defun ay-adoc--insert-block (header delim)
  "Insert a block fenced by DELIM under the HEADER line, point inside."
  (unless (bolp) (insert "\n"))
  (insert header "\n" delim "\n\n" delim "\n")
  (forward-line -2))

(defun ay-adoc-code-block ()
  "Insert a source block, prompting for the language."
  (interactive)
  (let ((lang (read-string "Language: " "text")))
    (ay-adoc--insert-block (format "[source,%s]" lang) "----")))

(defun ay-adoc-quote-block ()
  "Insert a quote block."
  (interactive)
  (ay-adoc--insert-block "[quote]" "____"))

(defun ay-adoc-insert-table (columns)
  "Insert a COLUMNS-wide table skeleton with a header row."
  (interactive "nColumns: ")
  (let* ((n    (max 1 columns))
         (spec (mapconcat #'identity (make-list n "1") ","))
         (row  (mapconcat #'identity (make-list n "| ") "")))
    (unless (bolp) (insert "\n"))
    (insert (format "[cols=\"%s\",options=\"header\"]\n|===\n%s\n\n%s\n|===\n"
                    spec row row))
    ;; Leave point in the first cell of the header row.
    (forward-line -4)
    (beginning-of-line)
    (re-search-forward "| " (line-end-position) t)))

(defun ay-adoc-insert-footnote ()
  "Insert a footnote, point inside the brackets."
  (interactive)
  (insert "footnote:[]")
  (backward-char 1))

(defun ay-adoc-insert-image ()
  "Insert an AsciiDoc image macro, prompting for the file path."
  (interactive)
  (let ((path (read-file-name "Image: ")))
    (insert (format "image::%s[]" path))))

(defun ay-adoc-insert-checkbox ()
  "Insert an unchecked list checkbox."
  (interactive)
  (insert "* [ ] "))

(defun ay-adoc-insert-rule ()
  "Insert a horizontal rule."
  (interactive)
  (unless (bolp) (insert "\n"))
  (insert "'''" "\n"))

(transient-define-prefix ay-adoc-menu ()
  "AsciiDoc formatting, insertion, lists and document actions."
  [["format"
    ("b" "bold"          adoc-insert-bold)
    ("i" "italic"        adoc-insert-italic)
    ("c" "code"          adoc-insert-monospace)
    ("s" "strikethrough" ay-adoc-strikethrough)
    ("u" "underline"     ay-adoc-underline)
    ("m" "highlight"     adoc-insert-highlight)]
   ["insert"
    ("h" "heading"       ay-adoc-insert-heading)
    ("l" "link"          adoc-insert-link)
    ("g" "image"         ay-adoc-insert-image)
    ("k" "code block"    ay-adoc-code-block)
    ("q" "quote block"   ay-adoc-quote-block)
    ("t" "table"         ay-adoc-insert-table)
    ("f" "footnote"      ay-adoc-insert-footnote)
    ("r" "rule"          ay-adoc-insert-rule)]]
  [["list"
    ("n" "item"          adoc-insert-list-item)
    ("x" "checkbox"      ay-adoc-insert-checkbox)
    ("<" "promote"       adoc-promote)
    (">" "demote"        adoc-demote)
    ("[" "move up"       adoc-move-list-item-up)
    ("]" "move down"     adoc-move-list-item-down)
    ("#" "renumber"      adoc-renumber-list)]
   ["document"
    ("p" "preview"       ay-preview)
    ("e" "export html"   adoc-export-html)
    ("a" "fold all"      adoc-cycle-buffer)
    ("d" "show images"   adoc-toggle-images)]])

;; ── Org ───────────────────────────────────
;; Document authoring only — no agenda, capture, scheduling or TODO state.
(defun ay-org-bold () (interactive) (org-emphasize ?*))
(defun ay-org-italic () (interactive) (org-emphasize ?/))
(defun ay-org-code () (interactive) (org-emphasize ?~))
(defun ay-org-verbatim () (interactive) (org-emphasize ?=))
(defun ay-org-strikethrough () (interactive) (org-emphasize ?+))
(defun ay-org-underline () (interactive) (org-emphasize ?_))
(defun ay-org-code-block () (interactive) (org-insert-structure-template "src"))
(defun ay-org-quote-block () (interactive) (org-insert-structure-template "quote"))

(defun ay-org-insert-image ()
  "Insert an org image link, prompting for the file path."
  (interactive)
  (let ((path (read-file-name "Image: ")))
    (insert (format "[[file:%s]]" path))))

(defun ay-org-insert-rule ()
  "Insert a horizontal rule."
  (interactive)
  (unless (bolp) (insert "\n"))
  (insert "-----\n"))

(transient-define-prefix ay-org-menu ()
  "Org formatting, insertion, lists and document actions."
  [["format"
    ("b" "bold"          ay-org-bold)
    ("i" "italic"        ay-org-italic)
    ("c" "code"          ay-org-code)
    ("v" "verbatim"      ay-org-verbatim)
    ("s" "strikethrough" ay-org-strikethrough)
    ("u" "underline"     ay-org-underline)]
   ["insert"
    ("h" "heading"       org-insert-heading)
    ("l" "link"          org-insert-link)
    ("g" "image"         ay-org-insert-image)
    ("k" "code block"    ay-org-code-block)
    ("q" "quote block"   ay-org-quote-block)
    ("t" "table"         org-table-create)
    ("f" "footnote"      org-footnote-new)
    ("r" "rule"          ay-org-insert-rule)]]
  [["list"
    ("n" "item"          org-insert-item)
    ("x" "checkbox"      org-toggle-checkbox)
    ("<" "promote"       org-metaleft)
    (">" "demote"        org-metaright)
    ("[" "move up"       org-metaup)
    ("]" "move down"     org-metadown)
    ("#" "bullet style"  org-cycle-list-bullet)]
   ["document"
    ("p" "preview"       ay-preview)
    ("e" "export"        org-export-dispatch)
    ("a" "fold all"      org-shifttab)
    ("d" "show images"   org-toggle-inline-images)]])

;; ── Pane / Window ─────────────────────────
(transient-define-prefix ay-pane-menu ()
  "Window pane management."
  [["navigate"
    ("a" "prev pane"    (lambda () (interactive) (other-window -1)))
    ("d" "next pane"    other-window)]
   ["split"
    ("s" "split right"  ay-split-right)
    ("S" "split below"  ay-split-below)]
   ["close"
    ("c" "close pane"   delete-window)
    ("C" "close others" delete-other-windows)]])

;; ── Apps ──────────────────────────────────
(transient-define-prefix ay-irc-menu ()
  "IRC network selection."
  [["connect to"
    ("l" "Libera.Chat"  ay-erc-libera)
    ("u" "Undernet"     ay-erc-undernet)]])

(transient-define-prefix ay-apps-menu ()
  "Applications."
  [["apps"
    ("t" "terminal"  eat)
    ("b" "browser"   eww)
    ("g" "gemini"    elpher)
    ("i" "irc →"     ay-irc-menu)]])

;; ── Context (here) menus ──────────────────
(transient-define-prefix ay-here-eww-menu ()
  "EWW browser actions."
  [["navigate"
    ("g" "go to URL"    eww)
    ("a" "back"         eww-back-url)
    ("d" "forward"      eww-forward-url)
    ("C-r" "reload"     eww-reload)]
   ["page"
    ("r" "reader mode"  eww-readable)
    ("t" "new buffer"   ay-eww-new-buffer)
    ("u" "copy URL"     ay-eww-copy-url)
    ("y" "copy link"    ay-eww-copy-link)]
   ["bookmarks"
    ("b" "list"         counsel-bookmark)
    ("B" "add"          ay-eww-add-bookmark)]])

(transient-define-prefix ay-here-elpher-menu ()
  "Elpher Gemini/Gopher actions."
  [["navigate"
    ("h" "home"          elpher-back-to-start)
    ("g" "go to"         elpher-go)
    ("a" "back"          elpher-back)
    ("o" "root dir"      elpher-root-dir)
    ("n" "next link"     elpher-next-link)
    ("N" "prev link"     elpher-prev-link)
    ("m" "jump to link"  elpher-jump)]
   ["page"
    ("C-r" "reload"      elpher-reload)
    ("w" "redraw"        elpher-redraw)
    ("." "view raw"      elpher-view-raw)
    ("d" "download"      elpher-download-current)
    ("i" "page info"     elpher-info-current)
    ("T" "toggle TLS"    elpher-toggle-tls)]]
  [["copy"
    ("u" "page URL"      elpher-copy-current-url)
    ("c" "link URL"      elpher-copy-link-url)]
   ["history"
    ("s" "page history"  elpher-show-history)
    ("S" "visited pages" elpher-show-visited-pages)]
   ["bookmarks"
    ("b" "list"          elpher-show-bookmarks)
    ("B" "add page"      elpher-bookmark-current)
    ("l" "add link"      elpher-bookmark-link)]])

(transient-define-prefix ay-here-erc-menu ()
  "ERC IRC actions."
  [["server"
    ("j" "join channel"  erc-join-channel)
    ("l" "channel list"  ay-erc-list)
    ("q" "quit IRC"      erc-quit-server)]
   ["channel"
    ("p" "part (leave)"  erc-part-from-channel)
    ("n" "names (members)" ay-erc-names)
    ("t" "next active"   erc-track-switch-buffer)]])

(transient-define-prefix ay-here-eat-menu ()
  "Eat terminal actions."
  [["terminal"
    ("c" "clear"  eat-reset)]])

(defun ay-here-menu ()
  "Open the context menu for the current major mode."
  (interactive)
  (cond
   ((derived-mode-p 'eww-mode)      (ay-here-eww-menu))
   ((derived-mode-p 'elpher-mode)   (ay-here-elpher-menu))
   ((derived-mode-p 'eat-mode)      (ay-here-eat-menu))
   ((derived-mode-p 'erc-mode)      (ay-here-erc-menu))
   ((derived-mode-p 'markdown-mode) (ay-markdown-menu))
   ((derived-mode-p 'adoc-mode)     (ay-adoc-menu))
   ((derived-mode-p 'org-mode)      (ay-org-menu))
   (t (message "No context menu for this mode"))))

;; ── Main Menu ─────────────────────────────
(transient-define-prefix ay-menu ()
  "Main menu."
  [["menu"
    ("f" "file →"     ay-file-menu)
    ("b" "buffers →"  ay-buffers-menu)
    ("p" "pane →"     ay-pane-menu)
    ("a" "apps →"     ay-apps-menu)
    ("v" "view →"     ay-view-menu)
    ("h" "here →"     ay-here-menu)
    ("s" "settings →" ay-settings-menu)
    ("q" "quit"       save-buffers-kill-emacs)]])

;; ── Preload menu targets ──────────────────
;; Transient loads each suffix command's package the first time a menu
;; is opened (View pulls in org/markdown/adoc/olivetti, Apps pulls in
;; eww/elpher/eat — ~0.5s total). Load them in idle time after startup
;; instead, one per tick, yielding as soon as there's keyboard input.
(defvar ay--preload-features
  '(olivetti markdown-mode adoc-mode org eww elpher eat erc org-indent)
  "Features loaded in the background after startup.")

(defun ay--preload-step ()
  (while (and ay--preload-features (not (input-pending-p)))
    (let ((inhibit-message t))
      (with-demoted-errors "Preload: %S"
        (require (pop ay--preload-features) nil t))))
  (when ay--preload-features
    (run-with-idle-timer 0.5 nil #'ay--preload-step)))

(add-hook 'emacs-startup-hook
          (lambda () (run-with-idle-timer 1 nil #'ay--preload-step)))
