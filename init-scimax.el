;; (string-join
;; (list "~" (or (getenv "EMACS_SCIMAX") ".emacs-scimax")) "/")
;; (format "~/%s" (or (getenv "EMACS_SCIMAX")
;;				      ".emacs-scimax"))

(let ((scimax-path (or (getenv "EMACS_SCIMAX")
		       (expand-file-name "~/.emacs.scimax"))))
  (setq scimax-dir (expand-file-name scimax-path)
	scimax-theme 'ef-winter
	;; scimax-theme 'leuven-dark
	;; package-user-dir (expand-file-name "elpa"  scimax-dir)
	user-emacs-directory scimax-path)

  ;; this ensures common packages write to ./var and ./etc inside
  ;; user-emacs-directory
  (require 'no-littering)
  (add-to-list 'load-path scimax-dir))

'(("emacs-lisp"
  (:background "LightCyan1"
	       :extend t))
 ("sh"
  (:background "gray90"
	       :extend t))
 ("python"
  (:background "DarkSeaGreen1"
	       :extend t))
 ("ipython"
  (:background "thistle1"
	       :extend t))
 ("jupyter-python"
  (:background "thistle1"
	       :extend t)))

;; emacs29 splits this into:
;;
;; - native-comp-jit-deny-list
;; - native-comp-bootstrap-deny-list
(setq native-comp-deferred-compilation-deny-list nil)

(require 'init)

(and (require 'envrc)
     (envrc-global-mode))



(defun dc/update-face (face1 face2)
  "Swap `face1' with the spec of `face2'."

  ;; TODO: won't survice swapping themes
  (if-let* ((face (get face2 'face))
	    (spec (cadar (get face2 'theme-face))))
      (face-spec-set face1 spec)))

(defface dc/org-src-python nil
  "Face for python source blocks")
(defface dc/org-src-emacs-lisp nil
  "Face for emacs-lisp source blocks")
(defface dc/org-src-sh nil
  "Face for sh source blocks")
(defface dc/org-src-ipython nil
  "Face for ipython source blocks")
(defface dc/org-src-jupyter-python nil
  "Face for jupyter-python source blocks")

;; (plist-get '(:background 'bg-changed-faint :extend t) :background )
;; (plist-get (cadr (nth 0 dc/org-src-block-colors)) :background)

;; (setq dc/org-src-block-colors
;;      '(("emacs-lisp" (:background 'bg-changed-faint :extend t))
;;	("sh" (:background 'bg-removed-faint :extend t))
;;	("python" (:background 'bg-added-faint :extend t) )
;;	("ipython" (:background 'bg-inactive :extend t))
;;	("jupyter-python" (:background 'bg-inactive :extend t))))

(defvar dc/org-src-block-colors
  '(("emacs-lisp" (:background 'bg-changed-faint :extend t))
    ("sh" (:background 'bg-removed-faint :extend t))
    ("python" (:background 'bg-added-faint :extend t) )
    ("ipython" (:background 'bg-inactive :extend t))
    ("jupyter-python" (:background 'bg-inactive :extend t)))
  "The ef-themes color symbols to use for org blocks of specific
languages. This may require refreshing the font-lock in the
buffer. Faces should be set to :extend once merged")

(defun dc/org-src-block-face (lang+spec &optional color)
  (if-let* ((this-lang (car lang+spec))
	    (this-spec (cadr lang+spec))
	    (this-color (plist-get this-spec :background))
	    (color (or color (ef-themes-get-color-value this-color)))
	    (facesym-name (format "dc/org-src-%s" this-lang))
	    (facesym (or (intern-soft facesym-name)
			 (intern facesym-name)))
	    (block-face (get facesym 'face))
	    (block-spec (plist-put (cl-copy-list this-spec)
				   :background color)))
      (progn (pp (list "success"
		       ;; lang+spec
		       ;; this-lang
		       ;; this-color
		       ;; facesym-name
		       this-spec
		       this-color
		       color
		       facesym-name
		       facesym
		       ;; block-face
		       block-spec))
	     (face-spec-set facesym block-spec))
    (pp (list "success"
	      ;; lang+spec
	      ;; this-lang
	      ;; this-color
	      ;; facesym-name
	      this-spec
	      this-color
	      color
	      facesym-name
	      facesym
	      ;; block-face
	      block-spec))
    (unless color
      (user-error "ef-themes color is nil"))
    (unless block-face
      (user-error "block-face for lang is nil"))
    (unless this-color
      (user-error "face spec requires :background to be set"))))

(defun dc/org-src-block-set-faces ()
  (interactive)
  )

;; (ef-themes-get-color-value (plist-get (cadr (nth 0 dc/org-src-block-colors)) :background))

;; (plist-get '(:background 'bg-changed-faint :extend t) :background)
;; (plist-put (cl-copy-list (cadr (nth 0 dc/org-src-block-colors))) :background 
;; 	   (ef-themes-get-color-value 'bg-changed-faint))
;; (dc/org-src-block-face (cadr (nth 0 dc/org-src-block-colors)))
;; (get 'dc/org-src-sh 'face)

(defun dc-sci/setup-look-and-feel ()
  (ef-themes-select 'ef-winter)

  (rainbow-mode)
  (rainbow-delimiters-mode)
  (highlight-symbol-mode)

  ;; (setq  org-src-block-faces
  ;; 	 `(("emacs-lisp" ,bg-changed-faint)
  ;; 	   ("sh" ,())
  ;; 	   ("python" (:background "DarkSeaGreen1" :extend t))
  ;; 	   ("ipython" (:background "thistle1" :extend t))
  ;; 	   ("jupyter-python" (:background "thistle1" :extend t))))
  )

(add-hook 'window-setup-hook #'dc-sci/setup-look-and-feel)

(unless (featurep 'scimax-jupyter)
  (warn "module scimax-jupyter not loaded"))

(if-let ((jp (executable-find "jupyter")))
    (message "Found jupyter: %s" jp)
  (warn "Couldn't find jupyter:"))
