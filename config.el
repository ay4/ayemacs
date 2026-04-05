;; config.el — User configuration loader
;;
;; Loads topic-specific config files from ~/.emacs.d/config/ in order.
;; Each file is self-contained and documented at the top.
;;
;;   keybindings.el — global keys, CUA, search, unbindings
;;   ui.el          — appearance, themes, frame border, headings
;;   editing.el     — indentation, ivy, org, markdown, typewriter, olivetti
;;   windows.el     — pane split/close, dimmer
;;   apps.el        — eat, eww, elpher, erc, bookmark+
;;   menus.el       — all transient menus

(let ((dir (expand-file-name "config/" user-emacs-directory)))
  (dolist (f '("keybindings" "ui" "editing" "windows" "apps" "menus"))
    (load (concat dir f) nil t)))
