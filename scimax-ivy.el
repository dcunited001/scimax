;;; scimax-ivy.el --- ivy functions for scimax  -*- lexical-binding: t -*-

;;; Commentary:
;;
(require 'counsel)

;; * Generic ivy actions

;; I usually want to be able to insert
(ivy-set-actions
 t
 '(("i" (lambda (x)
	  (with-ivy-window
	    (let (cand)
	      (setq cand (cond
			  ;; x is a string, the only sensible thing is to insert it
			  ((stringp x)
			   x)
			  ;; x is a list where the first element is a string
			  ((and (listp x) (stringp (first x)))
			   (first x))
			  (t
			   (format "%S" x))))
	      (unless (looking-at  " ") (insert " "))
	      (insert cand))))
    "insert candidate")
   (" " (lambda (x) (ivy-resume)) "resume")
   ("?" (lambda (x)
	  (interactive)
	  (describe-keymap ivy-minibuffer-map))
    "Describe keys")))

;; ** Extra projectile actions
;; Here I can open bash or finder when switching projects

(defun scimax-ivy-projectile-bash (x)
  "Open bash at X chosen from `projectile-completing-read'."
  (let* ((full-path (f-join (projectile-project-root) x))
	 (dir (if (file-directory-p full-path)
		  full-path
		(file-name-directory full-path))))
    (bash dir)
    ;; I use this to just get out of whatever called this to avoid visiting a
    ;; file for example.
    (recursive-edit)
    (ivy-quit-and-run)))


(defun scimax-ivy-projectile-finder (x)
  "Open finder at X chosen from `projectile-completing-read'."
  (let* ((full-path (f-join (projectile-project-root) x))
	 (dir (if (file-directory-p full-path)
		  full-path
		(file-name-directory full-path))))
    (finder dir)
    ;; I use this to just get out of whatever called this to avoid visiting a
    ;; file for example.
    (recursive-edit)
    (ivy-quit-and-run)))


(defun scimax-ivy-insert-project-link (x)
  "Insert a relative path link to X chosen from `projectile-completing-read'."
  (let* ((full-path (f-join (projectile-project-root) x))
	 (current-path (file-name-directory (buffer-file-name)))
	 (rel-path (file-relative-name full-path current-path)))
    (insert (format "[[%s]]" rel-path)))
  ;; I use this to just get out of whatever called this to avoid visiting a
  ;; file for example.
  (recursive-edit)
  (ivy-quit-and-run))


(defun scimax-ivy-magit-status (x)
  "Run magit status from `projectile-completing-read'.
Right now, it runs `magit-status' in the directory associated
with the entry."
  (cond
   ;; A directory, we can just get the status
   ((file-directory-p x)
    (let ((default-directory x))
      (magit-status-setup-buffer)))
   ;; something else?
   (t
    ;; What should we do on a file? show that file change? just do magit status?
    (let* ((full-path (f-join (projectile-project-root) x))
	   (dir (if (file-directory-p full-path)
		    full-path
		  (file-name-directory full-path))))

      (let ((default-directory dir))
	(magit-status-setup-buffer)))
    (recursive-edit)
    (ivy-quit-and-run))))


;; See `counsel-projectile-switch-project-action-ag'
;; (defun scimax-ivy-projectile-ag (x)
;;   "Run projectile-ag in the selected project X."
;;   (let ((default-directory x))
;;     (call-interactively #'projectile-ag)))

;; See `counsel-projectile-switch-project-action-rg'
;; (defun scimax-ivy-projectile-ripgrep (x)
;;   "Run projectile-ag in the selected project X."
;;   (let ((default-directory x))
;;     (call-interactively #'projectile-ripgrep)))


(defun scimax-ivy-projectile-org-heading (x)
  "Open a heading in the project X"
  (let ((default-directory x))
    (call-interactively #'ivy-org-jump-to-project-headline)))

;; See [[nb:scimax::elpa/counsel-projectile-20201015.1109/counsel-projectile.el::c53333]]
;; for a long list of actions in counsel-projectile
(cl-loop for projectile-cmd in '(projectile-completing-read
				 counsel-projectile-switch-project)
	 do
	 (ivy-add-actions
	  projectile-cmd 
	  '(
	    ;; xs runs shell, and xe runs eshell. This is nice for an external shell.
	    ("xb" scimax-ivy-projectile-bash "Open bash here.")
	    ("xf" scimax-ivy-projectile-finder  "Open Finder here.")

	    ;; This may not be useful, there is already v
	    ("xg" scimax-ivy-magit-status  "Magit status")
	    ("h" scimax-ivy-projectile-org-heading "Open project heading")
	    ("l" scimax-ivy-insert-project-link "Insert project link")))) 



(ivy-add-actions 'counsel-projectile-switch-project
		 '(("l" (lambda (x)
			  (insert (format "[[%s]]" x)))
		    "Insert link to project")))


(defun scimax-projectile-switch-project-transformer (project)
  "Add title from readme.org in file if it exists."
  (let ((title (when (file-exists-p (f-join project "readme.org"))
		 (with-temp-buffer
		   (insert-file-contents (f-join project "readme.org"))
		   (when (re-search-forward "#\\+title:\\(.*\\)" nil t)
		     (propertize (match-string 1)
				 'face '(:foreground "DodgerBlue1")))))))
    (format "%60s%s" (s-pad-right 60 " " project) (or title ""))))


(ivy-configure 'counsel-projectile-switch-project :display-transformer-fn
	       #'scimax-projectile-switch-project-transformer)
(ivy-configure 'projectile-switch-project :display-transformer-fn
	       #'scimax-projectile-switch-project-transformer)


;; ** Find file actions
;; I like to do a lot of things from find-file.
(ivy-add-actions
 'counsel-find-file
 '(("a" (lambda (x)
	  (unless (memq major-mode '(mu4e-compose-mode message-mode))
	    (compose-mail))
	  (mml-attach-file x))
    "Attach to email")
   ("c" (lambda (x) (kill-new (f-relative x))) "Copy relative path")
   ("4" (lambda (x) (find-file-other-window x)) "Open in new window")
   ("5" (lambda (x) (find-file-other-frame x)) "Open in new frame")
   ("C" (lambda (x) (kill-new x)) "Copy absolute path")
   ("d" (lambda (x) (dired x)) "Open in dired")
   ("D" (lambda (x) (delete-file x)) "Delete file")
   ("e" (lambda (x) (shell-command (format "open %s" x)))
    "Open in external program")
   ("f" (lambda (x)
	  "Open X in another frame."
	  (find-file-other-frame x))
    "Open in new frame")
   ("p" (lambda (path)
	  (with-ivy-window
	    (insert (f-relative path))))
    "Insert relative path")
   ("P" (lambda (path)
	  (with-ivy-window
	    (insert path)))
    "Insert absolute path")
   ("l" (lambda (path)
	  "Insert org-link with relative path"
	  (with-ivy-window
	    (insert (format "[[./%s]]" (f-relative path)))
	    (org-toggle-inline-images)
	    (org-toggle-inline-images)))
    "Insert org-link (rel. path)")
   ("L" (lambda (path)
	  "Insert org-link with absolute path"
	  (with-ivy-window
	    (insert (format "[[%s]]" path))
	    (org-toggle-inline-images)
	    (org-toggle-inline-images)))
    "Insert org-link (abs. path)")
   ("r" (lambda (path)
	  (rename-file path (read-string "New name: ")))
    "Rename")
   ("F" (lambda (path)
	  (finder (file-name-directory path)))
    "Open in finder/explorer")
   ("b" (lambda (path)
	  (bash (file-name-directory path)))
    "Open in bash")))


;; * ivy colors

(defun ivy-color-candidates ()
  "Get a list of candidates for `ivy-colors'."
  (save-selected-window
    (list-colors-display))
  (with-current-buffer (get-buffer "*Colors*")
    (prog1
	(cl-loop for line in (s-split "\n" (buffer-string))
		 collect
		 (append (list line)
			 (mapcar 's-trim
				 (mapcar 'substring (s-split "  " line t)))))
      (kill-buffer "*Colors*"))))


(defun ivy-colors ()
  "List colors in ivy."
  (interactive)
  (ivy-read "Color: " (ivy-color-candidates)
	    :action
	    '(1
	      ("i" (lambda (line)
		     (insert (second line)))
	       "Insert name")
	      ("c" (lambda (line)
		     (kill-new (second line)))
	       "Copy name")
	      ("h" (lambda (line)
		     (insert (car (last line))))
	       "Insert hex")
	      ("r" (lambda (line)
		     (insert (format "%s" (color-name-to-rgb (second line)))))
	       "Insert RGB")

	      ("m" (lambda (line) (message "%s" (cdr line)))))))

;; * ivy-top

(defcustom ivy-top-command
  "top -stats pid,command,user,cpu,mem,pstate,time -l 1"
  "Top command for `ivy-top'."
  :group 'scimax-ivy
  :type 'string)

(defun ivy-top ()
  (interactive)
  (let* ((output (shell-command-to-string ivy-top-command))
	 (lines (progn
		  (string-match "TIME" output)
		  (split-string (substring output (+ 1 (match-end 0))) "\n")))
	 (candidates (mapcar (lambda (line)
			       (list line (split-string line " " t)))
			     lines)))
    (ivy-read "process: " candidates)))


;; * ivy-ps


;; a data structure for a process
(defstruct ivy-ps user pid)


(defun ivy-ps ()
  "WIP: ivy selector for ps.
TODO: sorting, actions."
  (interactive)
  (let* ((output (shell-command-to-string "ps aux | sort -k 3 -r"))
	 (lines (split-string output "\n"))
	 (candidates (mapcar
		      (lambda (line)
			(cons line
			      (let ((f (split-string line " " t)))
				(make-ivy-ps :user (elt f 0) :pid (elt f 1)))))
		      lines)))
    (ivy-read "process: " candidates
	      :action
	      '(1
		("k" (lambda (cand) (message "%s" (ivy-ps-pid cand))) "kill")))))

(provide 'scimax-ivy)

;;; scimax-ivy.el ends here
