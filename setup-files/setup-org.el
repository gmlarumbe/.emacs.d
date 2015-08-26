;; Time-stamp: <2015-08-26 14:59:50 kmodi>
;; Hi-lock: (("\\(^;\\{3,\\}\\)\\( *.*\\)" (1 'org-hide prepend) (2 '(:inherit org-level-1 :height 1.3 :weight bold :overline t :underline t) prepend)))
;; Hi-Lock: end

;; Org Mode

;; Contents:
;;
;;  Org Variables
;;  Agenda and Capture
;;  Source block languages
;;  Defuns
;;    org-linkid - Support markdown-style link ids
;;  Diagrams
;;  Confirm evaluate
;;  epresent
;;  org-tree-slide
;;  Org Export
;;    ox-latex - LaTeX export
;;    ox-html - HTML export
;;    ox-beamer - Beamer export
;;    ox-reveal - Presentations using reveal.js
;;    ox-odt - ODT, doc export
;;    Custom Org Export related “packages”
;;  Bindings

(if (bound-and-true-p org-load-version-dev)
    ;; if `org-load-version-dev' is non-nil
    (add-to-list 'load-path (concat user-emacs-directory
                                    "elisp/org-mode/lisp/"))
  (when (bound-and-true-p org-load-version-8p2)
    ;; if `org-load-version-dev' is nil AND
    ;;    `org-load-version-8p2' is non-nil
    (add-to-list 'load-path (concat user-emacs-directory
                                    "elisp/org-mode-8p2/"))))

(use-package org
  :mode ("\\.org\\'" . org-mode)
  :config
  (progn
;;; Org Variables
    (setq org-agenda-archives-mode nil) ; required in org 8.0+
    (setq org-agenda-skip-comment-trees nil)
    (setq org-agenda-skip-function nil)
    (setq org-src-fontify-natively t) ; fontify code in code blocks
    ;; Display entities like \tilde, \alpha, etc in UTF-8 characters
    (setq org-pretty-entities t)
    ;; Allow _ and ^ characters to sub/super-script strings but only when
    ;; string is wrapped in braces
    (setq org-use-sub-superscripts         '{}) ; in-buffer rendering
    (setq org-export-with-sub-superscripts '{}) ; for exports
    ;; Render subscripts and superscripts in org buffers
    (setq org-pretty-entities-include-sub-superscripts t)
    (setq org-export-with-smart-quotes t)
    ;; active single key command execution when at beginning of a headline
    (setq org-use-speed-commands t)
    (setq org-log-done 'timestamp) ; Insert only timestamp when closing an org TODO item
    ;; (setq org-log-done 'note) ; Insert timestamp and note when closing an org TODO item
    ;; http://orgmode.org/manual/Closing-items.html
    (setq org-hide-leading-stars  t)
    ;; Prevent auto insertion of blank lines before headings and list items
    (setq org-blank-before-new-entry '((heading)
                                       (plain-list-item)))
    (setq org-completion-use-ido t) ; use ido for auto completion
    (setq org-return-follows-link t) ; Hitting <RET> while on a link follows the link
    (setq org-startup-folded 'showall)
    ;; fold / overview  - collapse everything, show only level 1 headlines
    ;; content          - show only headlines
    ;; nofold / showall - expand all headlines except the ones with :archive:
    ;;                    tag and property drawers
    ;; showeverything   - same as above but without exceptions
    (setq org-todo-keywords '((sequence "TODO" "SOMEDAY" "CANCELED" "DONE")))
    (setq org-todo-keyword-faces
          '(("TODO"     . org-todo)
            ("SOMEDAY"  . (:foreground "black" :background "#FFEF9F"))
            ("CANCELED" . (:foreground "#94BFF3" :weight bold :strike-through t))
            ("DONE"     . (:foreground "black" :background "#91ba31"))
            ))
    ;; Block entries from changing state to DONE while they have children
    ;; that are not DONE - http://orgmode.org/manual/TODO-dependencies.html
    (setq org-enforce-todo-dependencies t)
    (setq org-catch-invisible-edits 'smart) ; http://emacs.stackexchange.com/a/2091/115
    (setq org-startup-indented t) ; http://orgmode.org/manual/Clean-view.html
    (setq org-indent-indentation-per-level 1) ; default = 2
    (setq org-export-headline-levels 4)

    ;; Number of empty lines needed to keep an empty line between collapsed trees.
    ;; If you leave an empty line between the end of a subtree and the following
    ;; headline, this empty line is hidden when the subtree is folded.
    ;; Org-mode will leave (exactly) one empty line visible if the number of
    ;; empty lines is equal or larger to the number given in this variable.
    (setq org-cycle-separator-lines 2) ; default = 2

    ;; Footnote auto adjustment after insertion/deletion
    (setq org-footnote-auto-adjust t) ; `'sort' - only sort
                                        ; `'renumber' - only renumber
                                        ; `t' - sort and renumber
                                        ; `nil' - do nothing (default)

    (when (version<= (org-version) "8.2.99")
      ;; Re-define `org-get-buffer-tags' as defined in org-mode version 8.3+
      ;; for `counsel-org-tag' to work correctly in org-mode version 8.2.
      (defun org-get-buffer-tags ()
        "Get a table of all tags used in the buffer, for completion."
        (org-with-wide-buffer
         (goto-char (point-min))
         (let ((tag-re (concat org-outline-regexp-bol
                               "\\(?:.*?[ \t]\\)?"
                               (org-re ":\\([[:alnum:]_@#%:]+\\):[ \t]*$")))
               tags)
           (while (re-search-forward tag-re nil t)
             (dolist (tag (org-split-string (org-match-string-no-properties 1) ":"))
               (push tag tags)))
           (mapcar #'list (append org-file-tags (org-uniquify tags)))))))

;;; Agenda and Capture
    ;; http://orgmode.org/manual/Template-elements.html
    ;; http://orgmode.org/manual/Template-expansion.html
    (setq org-capture-templates
          '(("j" "Journal" entry ; `org-capture' binding + j
             (file+datetree (expand-file-name "journal.org" org-directory))
             "\n* %?\n  Entered on %U")
            ("n" "Note" entry ; `org-capture' binding + n
             (file (expand-file-name "notes.org" org-directory))
             "\n* %?\n  Context:\n    %i\n  Entered on %U")
            ("u" "UVM/System Verilog Notes" ; `org-capture' binding + u
             entry (file (expand-file-name "uvm.org" org-directory))
             "\n* %?\n  Context:\n    %i\n  Entered on %U")))

    (defvar modi/one-org-agenda-file (expand-file-name "agenda.files"
                                                       org-directory)
      "One file to contain a list of all org agenda files.")
    (setq org-agenda-files modi/one-org-agenda-file)
    (unless (file-exists-p modi/one-org-agenda-file)
      ;; http://stackoverflow.com/a/14072295/1219634
      ;; touch `modi/one-org-agenda-file'
      (write-region "" :ignore modi/one-org-agenda-file))

    ;; http://sachachua.com/blog/2013/01/emacs-org-task-related-keyboard-shortcuts-agenda/
    (defun sacha/org-agenda-done (&optional arg)
      "Mark current TODO as done.
This changes the line at point, all other lines in the agenda referring to
the same tree node, and the headline of the tree node in the Org-mode file."
      (interactive "P")
      (org-agenda-todo "DONE"))

    (defun sacha/org-agenda-mark-done-and-add-followup ()
      "Mark the current TODO as done and add another task after it.
Creates it at the same level as the previous task, so it's better to use
this with to-do items than with projects or headings."
      (interactive)
      (org-agenda-todo "DONE")
      (org-agenda-switch-to)
      (org-capture 0 "t")
      (org-metadown 1)
      (org-metaright 1))

    (defun sacha/org-agenda-new ()
      "Create a new note or task at the current agenda item.
Creates it at the same level as the previous task, so it's better to use
this with to-do items than with projects or headings."
      (interactive)
      (org-agenda-switch-to)
      (org-capture 0))

    (add-hook 'org-agenda-mode-hook
              (lambda ()
                (bind-keys
                 :map org-agenda-mode-map
                  ("x" . sacha/org-agenda-done)
                  ("X" . sacha/org-agenda-mark-done-and-add-followup)
                  ("N" . sacha/org-agenda-new))))

;;; Source block languages
    ;; Change the default app for opening pdf files from org
    ;; http://stackoverflow.com/a/9116029/1219634
    (add-to-list 'org-src-lang-modes '("systemverilog" . verilog))
    (add-to-list 'org-src-lang-modes '("dot"           . graphviz-dot))

    ;; Change .pdf association directly within the alist
    (setcdr (assoc "\\.pdf\\'" org-file-apps) "acroread %s")

;;; Defuns
    ;; http://emacs.stackexchange.com/a/13854/115
    ;; Heading▮   --(C-c C-t)--> * TODO Heading▮
    ;; * Heading▮ --(C-c C-t)--> * TODO Heading▮
    (defun modi/org-first-convert-to-heading (orig-fun &rest args)
      (let ((is-heading))
        (save-excursion
          (forward-line 0)
          (when (looking-at "^\\*")
            (setq is-heading t)))
        (unless is-heading
          (org-toggle-heading))
        (apply orig-fun args)))
    (advice-add 'org-todo :around #'modi/org-first-convert-to-heading)

    (defun modi/org-return-no-indent (&optional n)
      "Make `org-return' repeat the number passed through the argument"
      (interactive "p")
      (dotimes (cnt n)
        (org-return nil)))

    ;; http://emacs.stackexchange.com/a/10712/115
    (defun modi/org-delete-link ()
      "Replace an org link of the format [[LINK][DESCRIPTION]] with DESCRIPTION.
If the link is of the format [[LINK]], delete the whole org link.

In both the cases, save the LINK to the kill-ring.

Execute this command while the point is on or after the hyper-linked org link."
      (interactive)
      (when (derived-mode-p 'org-mode)
        (let ((search-invisible t) start end)
          (save-excursion
            (when (re-search-backward "\\[\\[" nil :noerror)
              (when (re-search-forward "\\[\\[\\(.*?\\)\\(\\]\\[.*?\\)*\\]\\]"
                                       nil :noerror)
                (setq start (match-beginning 0))
                (setq end   (match-end 0))
                (kill-new (match-string-no-properties 1)) ; Save link to kill-ring
                (replace-regexp "\\[\\[.*?\\(\\]\\[\\(.*?\\)\\)*\\]\\]" "\\2"
                                nil start end)))))))

;;;; org-linkid - Support markdown-style link ids
    (use-package org-linkid
      :load-path "elisp/org-linkid")

;;; Diagrams
    ;; http://pages.sachachua.com/.emacs.d/Sacha.html
    (setq org-ditaa-jar-path (expand-file-name
                              "ditaa.jar"
                              (concat user-emacs-directory "software/")))
    (setq org-plantuml-jar-path (expand-file-name
                                 "plantuml.jar"
                                 (concat user-emacs-directory "software/")))

    ;; (setq org-startup-with-inline-images t)
    ;; (add-hook 'org-babel-after-execute-hook 'org-display-inline-images)

    (org-babel-do-load-languages
     'org-babel-load-languages '((ditaa    . t)   ; activate ditaa
                                 (plantuml . t)   ; activate plantuml
                                 (latex    . t)   ; activate latex
                                 (dot      . t))) ; activate graphviz

;;; Confirm evaluate
    (defun my-org-confirm-babel-evaluate (lang body)
      (and (not (string= lang "ditaa"))    ; don't ask for ditaa
           (not (string= lang "plantuml")) ; don't ask for plantuml
           (not (string= lang "latex"))    ; don't ask for latex
           (not (string= lang "dot"))      ; don't ask for graphviz
           ))
    (setq org-confirm-babel-evaluate 'my-org-confirm-babel-evaluate)
    (setq org-confirm-elisp-link-function 'yes-or-no-p)

;;; epresent
    (use-package epresent
      :commands (epresent-run))

;;; org-tree-slide
    ;; https://github.com/takaxp/org-tree-slide
    (use-package org-tree-slide
      :load-path "elisp/org-tree-slide"
      :commands (org-tree-slide-mode)
      :init
      (progn
        (bind-key "<C-S-f8>" #'org-tree-slide-mode modi-mode-map))
      :config
      (progn
        (setq org-tree-slide--lighter " Slide")

        (defvar org-tree-slide-text-scale 3
          "Text scale ratio to default when `org-tree-slide-mode' is enabled.")

        (defun org-tree-slide-my-profile ()
          "Customize org-tree-slide variables.
  `org-tree-slide-header'            => nil
  `org-tree-slide-slide-in-effect'   => nil
  `org-tree-slide-heading-emphasis'  => nil
  `org-tree-slide-cursor-init'       => t
  `org-tree-slide-modeline-display'  => 'lighter
  `org-tree-slide-skip-done'         => nil
  `org-tree-slide-skip-comments'     => t
"
          (interactive)
          (setq org-tree-slide-text-scale         2)
          (setq org-tree-slide-header             nil)
          (setq org-tree-slide-slide-in-effect    nil)
          (setq org-tree-slide-heading-emphasis   nil)
          (setq org-tree-slide-cursor-init        t)
          (setq org-tree-slide-modeline-display   'lighter)
          (setq org-tree-slide-skip-done          nil)
          (setq org-tree-slide-skip-comments      t)
          (setq org-tree-slide-activate-message   "Starting org presentation.")
          (setq org-tree-slide-deactivate-message "Ended presentation."))

        (defun my/org-tree-slide-start ()
          (interactive)
          (modi/toggle-one-window 4) ; force 1 window
          (text-scale-set org-tree-slide-text-scale)
          (org-tree-slide-my-profile))

        (defun my/org-tree-slide-stop()
          (interactive)
          (modi/toggle-one-window) ; toggle 1 window
          (text-scale-set 0))

        (add-hook 'org-tree-slide-play-hook #'my/org-tree-slide-start)
        ;; (remove-hook 'org-tree-slide-play-hook #'my/org-tree-slide-start)
        (add-hook 'org-tree-slide-stop-hook #'my/org-tree-slide-stop)
        ;; (remove-hook 'org-tree-slide-stop-hook #'my/org-tree-slide-stop)

        (bind-key "<left>"   #'org-tree-slide-move-previous-tree                             org-tree-slide-mode-map)
        (bind-key "<right>"  #'org-tree-slide-move-next-tree                                 org-tree-slide-mode-map)
        (bind-key "C-0"      (lambda () (interactive) (text-scale-set org-tree-slide-text-scale)) org-tree-slide-mode-map)
        (bind-key "C-="      (lambda () (interactive) (text-scale-increase 1))                    org-tree-slide-mode-map)
        (bind-key "C--"      (lambda () (interactive) (text-scale-decrease 1))                    org-tree-slide-mode-map)
        (bind-key "C-1"      #'org-tree-slide-content                                        org-tree-slide-mode-map)
        (bind-key "C-2"      #'org-tree-slide-my-profile                                     org-tree-slide-mode-map)
        (bind-key "C-3"      #'org-tree-slide-simple-profile                                 org-tree-slide-mode-map)
        (bind-key "C-4"      #'org-tree-slide-presentation-profile                           org-tree-slide-mode-map)))

;;; Org Export
    (use-package ox
      :config
      (progn
;;;; ox-latex - LaTeX export
        (use-package ox-latex
          :config
          (progn
            (defvar modi/ox-latex-use-minted t
              "Use `minted' package for listings.")

            (when (not (version<= (org-version) "8.2.99"))
              ;; org-mode version 8.3+
              (setq org-latex-prefer-user-labels t))

            ;; ox-latex patches
            (load (expand-file-name
                   "ox-latex-patches.el"
                   (concat user-emacs-directory "elisp/patches/"))
                  nil :nomessage)

            ;; Previewing latex fragments in org mode
            ;; http://orgmode.org/worg/org-tutorials/org-latex-preview.html
            ;; (setq org-latex-create-formula-image-program 'dvipng) ; NOT Recommended
            (setq org-latex-create-formula-image-program 'imagemagick) ; Recommended

            ;; Below will output tex files with
            ;;   \usepackage[FIRST STRING IF NON-EMPTY]{SECOND STRING}
            ;; The org-latex-packages-alist is a list of cells of the format:
            ;;   ("options" "package" SNIPPET-FLAG)
            ;; SNIPPET-FLAG is non-nil by default. So unless this flag is set
            ;; to nil, that package will be used even when previewing latex
            ;; fragments using the `C-c C-x C-l' binding
            (setq org-latex-packages-alist
                  '(
                    ;; % 0 paragraph indent, adds vertical space between paragraphs
                    ;; http://en.wikibooks.org/wiki/LaTeX/Paragraph_Formatting
                    ("" "parskip")
                    ;; Graphics package for more complicated figures
                    ("" "tikz")
                    ("" "caption")
                    ;;
                    ;; Packages suggested to be added for previewing latex fragments
                    ;; http://orgmode.org/worg/org-tutorials/org-latex-preview.html
                    ("mathscr" "eucal")
                    ("" "latexsym")))

            ;; Prevent tables/figures from one section to float into another section
            ;; http://tex.stackexchange.com/a/282/52678
            (add-to-list 'org-latex-packages-alist '("section" "placeins"))

            ;; Prevent an image from floating to a different location
            ;; http://tex.stackexchange.com/a/8633/52678
            (add-to-list 'org-latex-packages-alist '("" "float"))
            ;; "H" option is from the `float' package.
            ;; That prevents the images from floating around.
            (setq org-latex-default-figure-position "H") ; figures are NOT floating
            ;; (setq org-latex-default-figure-position "htb") ; default - figures are floating

            (if modi/ox-latex-use-minted
                ;; using minted
                ;; https://github.com/gpoore/minted
                (progn
                  (setq org-latex-listings 'minted) ; default nil
                  (if (eq org-latex-create-formula-image-program 'dvipng)
                      ;; If `org-latex-create-formula-image-program' is set to
                      ;; `'dvipng', minted package cannot be used to show latex
                      ;; previews.
                      (add-to-list 'org-latex-packages-alist '("" "minted" nil))
                    (add-to-list 'org-latex-packages-alist '("" "minted")))

                  ;; minted package options (applied to embedded source codes)
                  (setq org-latex-minted-options
                        '(("linenos")
                          ("numbersep"   "5pt")
                          ("frame"       "none") ; box frame is created by the mdframed package
                          ("framesep"    "2mm")
                          ;; ("fontfamily"  "zi4") ; required only when using pdflatex
                                        ; instead of xelatex
                          ;; minted 2.0 specific features
                          ("breaklines") ; line wrapping within code blocks
                          )))
              ;; not using minted
              (progn
                (add-to-list 'org-latex-packages-alist '("" "listings"))
                ;; Commented out below because it clashes with `placeins' package
                ;; (add-to-list 'org-latex-packages-alist '("" "color"))
                ))

            ;; `-shell-escape' is required when converting a .tex file
            ;; containing `minted' package to a .pdf

            ;; Run pdflatex multiple times to get the cross-references right
            ;; (setq org-latex-pdf-process '("pdflatex -shell-escape %f"
            ;;                               "pdflatex -shell-escape %f"
            ;;                               "pdflatex -shell-escape %f"))

            ;; http://orgmode.org/worg/org-faq.html#using-xelatex-for-pdf-export
            ;; latexmk runs pdflatex/xelatex (whatever is specified) multiple times
            ;; automatically to resolve the cross-references.
            ;; (setq org-latex-pdf-process '("latexmk -xelatex -quiet -shell-escape -f %f"))

            ;; Run xelatex multiple times to get the cross-references right
            (setq org-latex-pdf-process '("xelatex -shell-escape %f"
                                          "xelatex -shell-escape %f"
                                          "xelatex -shell-escape %f"
                                          "xelatex -shell-escape %f"))))

;;;; ox-html - HTML export
        (use-package ox-html
          :config
          (progn
            ;; ox-html patches
            (load (expand-file-name
                   "ox-html-patches.el"
                   (concat user-emacs-directory "elisp/patches/"))
                  nil :nomessage)

            ;; Remove HTML tags from in-between <title>..</title> else they show
            ;; up verbatim in the browser tabs e.g. "Text <br> More Text"
            (defun modi/ox-html-remove-tags-from-title-tag (orig-return-val)
              (replace-regexp-in-string ".*<title>.*\\(<.*>\\).*</title>.*"
                                        ""
                                        orig-return-val
                                        :fixedcase :literal 1))
            (advice-add 'org-html--build-meta-info :filter-return
                        #'modi/ox-html-remove-tags-from-title-tag)

            (use-package ox-html-fancybox
              :load-path "elisp/ox-html-fancybox")

            ;; Center align the tables when exporting to HTML
            ;; Note: This aligns the whole table, not the table columns
            (setq org-html-table-default-attributes
                  '(:border "2"
                    :cellspacing "0"
                    :cellpadding "6"
                    :rules "groups"
                    :frame "hsides"
                    :align "center"
                    ;; below class requires bootstrap.css ( http://getbootstrap.com )
                    :class "table-striped"))

            ;; Customize the HTML postamble
            (setq org-html-postamble t) ; default value = 'auto
            (setq org-html-postamble-format
                  `(("en"
                     ,(concat "Exported using "
                              ;; "%c" is replaced with `org-html-creator-string'
                              ;; Emacs <VERSION> (Org mode <VERSION>)
                              "<div style=\"display: inline\" class=\"creator\">"
                              "%c</div> "
                              "by %e. — "
                              "<div style=\"display: inline\" class=\"date\">"
                              "%d</div>"))))

            (setq org-html-htmlize-output-type 'css) ; default: 'inline-css
            (setq org-html-htmlize-font-prefix "org-") ; default: "org-"

            ;; http://emacs.stackexchange.com/a/14560/115
            (defvar modi/htmlize-html-file (concat user-home-directory
                                                   "temp/htmlize_temp.html")
              "Name of the html file exported by `modi/htmlize-region-as-html-file'.")
            (defvar modi/htmlize-css-file (concat user-emacs-directory
                                                  "misc/css/leuven_theme.css")
              "CSS file to be embedded in the html file created using the
             `modi/htmlize-region-as-html-file' function.")
            (defun modi/htmlize-region-as-html-file (open-in-browser)
              "Export the selected region to an html file. If a region is not
             selected, export the whole buffer.

             If OPEN-IN-BROWSER is non-nil, also open the exported html file in
             the default browser."
              (interactive "P")
              (let ((org-html-htmlize-output-type 'css)
                    (org-html-htmlize-font-prefix "org-")
                    start end html-string)
                (if (use-region-p)
                    (progn
                      (setq start (region-beginning))
                      (setq end   (region-end)))
                  (progn
                    (setq start (point-min))
                    (setq end   (point-max))))
                (setq html-string (org-html-htmlize-region-for-paste start end))
                (with-temp-buffer
                  ;; Insert the `modi/htmlize-css-file' contents in the temp buffer
                  (insert-file-contents modi/htmlize-css-file nil nil nil :replace)
                  ;; Go to the beginning of the buffer and insert comments and
                  ;; opening tags for `html', `head' and `style'. These are
                  ;; inserted *above* the earlier inserted css code.
                  (goto-char (point-min))
                  (insert (concat "<!-- This file is generated using the "
                                  "modi/htmlize-region-as-html-file function\n"
                                  "from https://github.com/kaushalmodi/.emacs.d/"
                                  "blob/master/setup-files/setup-org.el -->\n"))
                  (insert "<html>\n<head>\n<style media=\"screen\" type=\"text/css\">\n")
                  ;; Go to the end of the buffer (end of the css code) and
                  ;; insert the closing tags for `style' and `head' and opening
                  ;; tag for `body'.
                  (goto-char (point-max))
                  (insert "</style>\n</head>\n<body>\n")
                  ;; Insert the HTML for fontified text in `html-string'.
                  (insert html-string)
                  ;; Close the `body' and `html' tags.
                  (insert "</body>\n</html>\n")
                  (write-file modi/htmlize-html-file)
                  (when open-in-browser
                    (browse-url-of-file modi/htmlize-html-file)))))
            (bind-key "H" #'modi/htmlize-region-as-html-file region-bindings-mode-map)))

;;;; ox-beamer - Beamer export
        (use-package ox-beamer
          :commands (org-beamer-export-as-latex
                     org-beamer-export-to-latex
                     org-beamer-export-to-pdf)
          :config
          (progn
            ;; allow for export=>beamer by placing
            ;; #+LaTeX_CLASS: beamer in org files
            (add-to-list 'org-latex-classes
                         '("beamer"
                           "\\documentclass[presentation]{beamer}"
                           ("\\section{%s}"        . "\\section*{%s}")
                           ("\\subsection{%s}"     . "\\subsection*{%s}")
                           ("\\subsubsection{%s}"  . "\\subsubsection*{%s}")))))

;;;; ox-reveal - Presentations using reveal.js
        ;; Download reveal.js from https://github.com/hakimel/reveal.js/
        (use-package ox-reveal
          :load-path "elisp/ox-reveal"
          :config
          (progn
            (setq org-reveal-root (concat user-emacs-directory "software/reveal.js/"))
            (setq org-reveal-hlevel 1)
            (setq org-reveal-theme "default") ; beige blood moon night serif simple sky solarized
            (setq org-reveal-mathjax t) ; Use mathjax.org to render LaTeX equations

            ;; Override the `org-reveal-export-to-html' function to generate
            ;; files with “_slides” suffix. So “man.org” will export to
            ;; “man_slides.html”. That way we can have separate html files from
            ;; html and reveal exports.
            (defun org-reveal-export-to-html
                (&optional async subtreep visible-only body-only ext-plist)
              "Export current buffer to a reveal.js HTML file."
              (interactive)
              (let* ((extension (concat "_slides." org-html-extension))
                     (file (org-export-output-file-name extension subtreep))
                     (clientfile (org-export-output-file-name
                                  (concat "_client" extension) subtreep)))

                ;; export filename_client HTML file if multiplexing
                (setq client-multiplex nil)
                (setq retfile (org-export-to-file 'reveal file
                                async subtreep visible-only body-only ext-plist))

                ;; export the client HTML file if client-multiplex is set true
                ;; by previous call to org-export-to-file
                (if (eq client-multiplex t)
                    (org-export-to-file 'reveal clientfile
                      async subtreep visible-only body-only ext-plist))
                (cond (t retfile))))))

;;;; ox-odt - ODT, doc export
        ;; http://stackoverflow.com/a/22990257/1219634
        (use-package ox-odt
          :disabled
          :config
          (progn
            ;; Auto convert the exported .odt to .doc (MS Word 97) format
            ;; Requires the soffice binary packaged with openoffice
            (setq org-odt-preferred-output-format "doc")))

        (defun modi/org-export-to-html-txt-pdf ()
          "Export the org file to multiple formats."
          (interactive)
          (org-html-export-to-html)
          (org-ascii-export-to-ascii)
          (org-latex-export-to-pdf))

;;;; Custom Org Export related “packages”
        ;; Auto update line numbers for source code includes when exporting
        (use-package org-include-src-lines
          :load-path "elisp/org-include-src-lines")

        ;; Replace include pdf files with images when exporting
        (use-package org-include-img-from-pdf
          :load-path "elisp/org-include-img-from-pdf")

        ;; Auto extract images from zip files
        (use-package org-include-img-from-archive
          :load-path "elisp/org-include-img-from-archive")
        ))

;;; Bindings
    ;; http://endlessparentheses.com/emacs-narrow-or-widen-dwim.html
    ;; Pressing `C-x C-s' while editing org source code blocks saves and exits
    ;; the edit.
    (with-eval-after-load 'org-src
      (bind-key "C-x C-s" #'org-edit-src-exit org-src-mode-map))

    ;; http://orgmode.org/manual/Easy-Templates.html
    ;; http://oremacs.com/2015/03/07/hydra-org-templates
    ;; https://github.com/abo-abo/hydra/wiki/Org-mode-block-templates
    (defun hot-expand (str)
      "Expand org template."
      (insert str)
      (org-try-structure-completion))

    (defhydra hydra-org-template (:color blue
                                  :hint nil)
      "
org-template:  _c_enter        _s_rc          e_x_ample           _v_erilog        _t_ext           _I_NCLUDE:
               _l_atex         _h_tml         _V_erse             _m_atlab         _L_aTeX:         _H_TML:
               _a_scii         _q_uote        _e_macs-lisp        _S_hell          _i_ndex:         _A_SCII:
"
      ("s" (hot-expand "<s")) ; #+BEGIN_SRC ... #+END_SRC
      ("e" (progn
             (hot-expand "<s")
             (insert "emacs-lisp")
             (forward-line)))
      ("v" (progn
             (hot-expand "<s")
             (insert "systemverilog")
             (forward-line)))
      ("m" (progn
             (hot-expand "<s")
             (insert "matlab")
             (forward-line)))
      ("S" (progn
             (hot-expand "<s")
             (insert "sh")
             (forward-line)))
      ("t" (progn
             (hot-expand "<s")
             (insert "text")
             (forward-line)))
      ("x" (hot-expand "<e")) ; #+BEGIN_EXAMPLE ... #+END_EXAMPLE
      ("q" (hot-expand "<q")) ; #+BEGIN_QUOTE ... #+END_QUOTE
      ("V" (hot-expand "<v")) ; #+BEGIN_VERSE ... #+END_VERSE
      ("c" (hot-expand "<c")) ; #+BEGIN_CENTER ... #+END_CENTER
      ("l" (hot-expand "<l")) ; #+BEGIN_LaTeX ... #+END_LaTeX
      ("L" (hot-expand "<L")) ; #+LaTeX:
      ("h" (hot-expand "<h")) ; #+BEGIN_HTML ... #+END_HTML
      ("H" (hot-expand "<H")) ; #+HTML:
      ("a" (hot-expand "<a")) ; #+BEGIN_ASCII ... #+END_ASCII
      ("A" (hot-expand "<A")) ; #+ASCII:
      ("i" (hot-expand "<i")) ; #+INDEX: line
      ("I" (hot-expand "<I")) ; #+INCLUDE: line
      ("<" self-insert-command "<")
      ("o" nil         "quit"))

    (defun modi/org-template-maybe ()
      "Insert org-template if point is at the beginning of the line,
else call `self-insert-command'."
      (interactive)
      (if (looking-back "^")
          (hydra-org-template/body)
        (self-insert-command 1)))

    (defun modi/reset-local-set-keys ()
      (local-unset-key (kbd "<f10>"))
      (local-unset-key (kbd "<s-f10>"))
      (local-unset-key (kbd "<S-f10>"))
      (local-unset-key (kbd "<C-f10>")))
    (add-hook 'org-mode-hook #'modi/reset-local-set-keys)

    (bind-keys
     :map org-mode-map
      ("C-m" . modi/org-return-no-indent)
      (">"   . modi/org-template-maybe))

    (bind-keys
     :map modi-mode-map
      ("C-c a" . org-agenda)
      ("C-c c" . org-capture))))


(provide 'setup-org)

;; C-c C-e l l <-- Do org > tex
;; C-c C-e l p <-- Do org > tex > pdf using the command specified in
;;                 `org-latex-pdf-process' list
;; C-c C-e l o <-- Do org > tex > pdf and open the pdf file using the app
;;                 associated with pdf files defined in `org-file-apps'

;; When the cursor is on an existing link, `C-c C-l' allows you to edit the link
;; and description parts of the link.

;; C-c C-x f <-- Insert footnote

;; C-c C-x C-l <-- Preview latex fragment in place; C-c C-c to exit that preview.

;; Auto-completions http://orgmode.org/manual/Completion.html
;; \ M-TAB <- TeX symbols
;; ​* M-TAB <- Headlines; useful when doing [[* Partial heading M-TAB when linking to headings
;; #+ M-TAB <- org-mode special keywords like #+DATE, #+AUTHOR, etc

;; Speed-keys are awesome! http://orgmode.org/manual/Speed-keys.html

;; Easy Templates http://orgmode.org/manual/Easy-Templates.html
;; To insert a structural element, type a ‘<’, followed by a template selector
;; and <TAB>. Completion takes effect only when the above keystrokes are typed
;; on a line by itself.
;; s 	#+BEGIN_SRC ... #+END_SRC
;; e 	#+BEGIN_EXAMPLE ... #+END_EXAMPLE
;; l 	#+BEGIN_LaTeX ... #+END_LaTeX
;; L 	#+LaTeX:
;; h 	#+BEGIN_HTML ... #+END_HTML
;; H 	#+HTML:
;; I 	#+INCLUDE: line

;; Disable selected org-mode markup character on per-file basis
;; http://emacs.stackexchange.com/a/13231/115

;; How to modify `org-emphasis-regexp-components'
;; http://emacs.stackexchange.com/a/13828/115

;; Installing minted.sty
;; In order to have that tex convert to pdf, you have to ensure that you have
;; minted.sty in your TEXMF folder.
;;  - To know if minted.sty in correct path do "kpsewhich minted.sty".
;;  - If it is not found, download from http://www.ctan.org/tex-archive/macros/latex/contrib/minted
;;  - Generate minted.sty by "tex minted.ins"
;;  - To know your TEXMF folder, do "kpsewhich -var-value=TEXMFHOME"
;;  - For me TEXMF folder was ~/texmf
;;  - Move the minted.sty to your $TEXMF/tex/latex/commonstuff folder.
;;  - Do mkdir -p ~/texmf/tex/latex/commonstuff if that folder hierarchy doesn't exist
;;  - Do "mktexlsr" to refresh the sty database
;;  - Generate pdf from the org exported tex by "pdflatex -shell-escape FILE.tex"

;; Sources for org > tex > pdf conversion:
;;  - http://nakkaya.com/2010/09/07/writing-papers-using-org-mode/
;;  - http://mirrors.ctan.org/macros/latex/contrib/minted/minted.pdf

;; To have an org document auto update the #+DATE: keyword during exports, use:
;;   #+DATE: {{{time(%b %d %Y\, %a)}}}
;; The time format here can be anything as documented in `format-time-string' fn.

;; Local Variables:
;; eval: (aggressive-indent-mode -1)
;; End:
