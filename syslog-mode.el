;;; syslog-mode.el --- Major-mode for viewing log files

;; Filename: syslog-mode.el
;; Description: Major-mode for viewing log files
;; Author: Harley Gorrell <harley@panix.com>
;; Maintainer: Joe Bloggs <vapniks@yahoo.com>
;; Created: 2003-03-17 18:50:12 Harley Gorrell
;; URL: https://github.com/vapniks/syslog-mode
;; Keywords: unix
;; Compatibility: GNU Emacs 24.3.1
;; Package-Requires:  ((hide-lines "20130623") (ov "20150311"))
;;
;; Features that might be required by this library:
;;
;; hide-lines cl ido dash dired+ ov
;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;;; Commentary:
;; * Handy functions for looking at system logs.
;; * Fontifys the date and su messages.

;;; Keybindings
;; "C-down" : syslog-boot-start
;; "R"      : revert-buffer
;; "/"      : syslog-filter-lines
;; "g"      : hide-lines-show-all
;; "h r"    : highlight-regexp
;; "h p"    : highlight-phrase
;; "h l"    : highlight-lines-matching-regexp
;; "h u"    : unhighlight-regexp
;; "C-/"    : syslog-filter-dates
;; "D"      : open dired buffer in log directory (`syslog-log-file-directory')
;; "j"      : ffap
;; "<"      : syslog-previous-file
;; ">"      : syslog-next-file
;; "o"      : syslog-open-files
;; "q"      : quit-window

;;; Commands:
;;
;; Below is a complete list of commands:
;;
;;  `syslog-shell-command'
;;    Execute a shell COMMAND synchronously, with prefix arg (SUDOP) run under sudo.
;;    Keybinding: !
;;  `syslog-append-files'
;;    Append FILES into buffer BUF.
;;    Keybinding: a
;;  `syslog-prepend-files'
;;    Prepend FILES into buffer BUF.
;;    Keybinding: M-x syslog-prepend-files
;;  `syslog-open-files'
;;    Insert log FILES into new buffer.
;;    Keybinding: o
;;  `syslog-view'
;;    Open a view of syslog files with optional filters and highlights applied.
;;    Keybinding: v
;;  `syslog-previous-file'
;;    Open the previous logfile backup, or the next one if a prefix arg is used.
;;    Keybinding: <
;;  `syslog-next-file'
;;    Open the next logfile.
;;    Keybinding: >
;;  `syslog-move-next-file'
;;    Move to the next file in the current `syslog-mode' buffer.
;;    Keybinding: <M-down>
;;  `syslog-move-previous-file'
;;    Move to the next file in the current `syslog-mode' buffer.
;;    Keybinding: <M-up>
;;  `syslog-toggle-filenames'
;;    Toggle the display of filenames before each line.
;;    Keybinding: t
;;  `syslog-filter-lines'
;;    Restrict buffer to blocks of text between matching regexps.
;;    Keybinding: /
;;  `syslog-filter-dates'
;;    Restrict buffer to lines between times START and END (Emacs time lists).
;;    Keybinding: C-/
;;  `syslog-mode'
;;    Major mode for working with system logs.
;;    Keybinding: M-x syslog-mode
;;  `syslog-count-matches'
;;    Count strings which match the given pattern.
;;    Keybinding: c
;;  `syslog-boot-start'
;;    Jump forward in the log to when the system booted.
;;    Keybinding: <C-down>
;;  `syslog-whois-reverse-lookup'
;;    This is a wrapper around the `whois' command using symbol at point as default search string.
;;    Keybinding: W
;;
;;; Customizable Options:
;;
;; Below is a list of customizable options:
;;
;;  `syslog-mode-hook'
;;    *Hook to setup `syslog-mode'.
;;    default = nil
;;  `syslog-views'
;;    A list of views.
;;    default = nil
;;  `syslog-datetime-regexp'
;;    A regular expression matching the date-time at the beginning of each line in the log file.
;;  `syslog-log-file-directory'
;;    The directory in which log files are stored.
;;    default = "/var/log/"

;; All of the above can customized by:
;;      M-x customize-group RET syslog-mode RET
;;

;;; Installation:
;;
;; Put syslog-mode.el in a directory in your load-path, e.g. ~/.emacs.d/
;; You can add a directory to your load-path with the following line in ~/.emacs
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;; where ~/elisp is the directory you want to add
;; (you don't need to do this for ~/.emacs.d - it's added by default).
;;
;; Add the following to your ~/.emacs startup file.
;;
;; (require 'syslog-mode)



;;; Change log:
;;
;; 21-03-2013    Joe Bloggs
;;    Added functions and keybindings for filtering
;;    lines by regexps or dates, and for highlighting,
;;    and quick key for find-file-at-point
;;
;; 20-03-2013    Christian Giménez
;;    Added more keywords for font-lock.
;;
;; 16-03-2003 : Updated URL and contact info.

;;; Acknowledgements:
;;
;;  Harley Gorrell  (Author)
;;  Christian Giménez
;;

;; If anyone wants to make changes please fork the following github repo: https://github.com/vapniks/syslog-mode

;;; TODO: statistical reporting - have a regular expression to match item type, then report counts of each item type.
;;        also statistics on number of items per hour/day/week/etc.


;;; Require
(require 'hide-lines)
(eval-when-compile (require 'cl))
(require 'ido)
(require 'hi-lock)
(require 'net-utils)
(require 'ov)

;;; Code:

;; Setup
;; simple-call-tree-info: DONE  
(defgroup syslog nil
  "syslog-mode - a major mode for viewing log files"
  :link '(url-link "https://github.com/vapniks/syslog-mode"))

;; simple-call-tree-info: DONE  
(defcustom syslog-mode-hook nil
  "*Hook to setup `syslog-mode'."
  :group 'syslog
  :type 'hook)

;; simple-call-tree-info: DONE  
(defvar syslog-mode-load-hook nil
  "*Hook to run when `syslog-mode' is loaded.")

;;;###autoload
;; simple-call-tree-info: DONE
(defvar syslog-setup-on-load nil
  "*If not nil setup syslog mode on load by running syslog-add-hooks.")

;; I also use "Alt" as C-c is too much to type for cursor motions.
;; simple-call-tree-info: DONE
(defvar syslog-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Ctrl bindings
    (define-key map [C-down] 'syslog-boot-start)
    (define-key map "R" 'revert-buffer)
    (define-key map "/" 'syslog-filter-lines)
    (define-key map "g" 'hide-lines-show-all)
    (define-prefix-command 'syslog-highlight-map)
    (define-key map "h" 'syslog-highlight-map)
    (define-key map (kbd "h r") 'highlight-regexp)
    (define-key map (kbd "h p") 'highlight-phrase)
    (define-key map (kbd "h l") 'highlight-lines-matching-regexp)
    (define-key map (kbd "h u") 'unhighlight-regexp)
    (define-key map (kbd "h U") 'highlight-regexp-unique)
    (define-key map (kbd "C-/") 'syslog-filter-dates)

    (define-key map "D" (lambda nil (interactive) (dired syslog-log-file-directory)))
    (define-key map "j" 'ffap)
    (define-key map "f" 'ffap)
    (define-key map "<" 'syslog-previous-file)
    (define-key map ">" 'syslog-next-file)
    (define-key map "o" 'syslog-open-files)
    (define-key map "a" 'syslog-append-files)
    (define-key map "p" 'syslog-prepend-files)
    (define-key map "v" 'syslog-view)
    (define-key map "c" 'syslog-count-matches)
    (define-key map "x" 'syslog-extract-matches)
    (define-key map "k" 'hide-lines-kill-hidden)
    (define-key map "W" 'syslog-whois-reverse-lookup)
    (define-key map "q" 'quit-window)
    (define-key map "!" 'syslog-shell-command)
    (define-key map (kbd "<M-down>") 'syslog-move-next-file)
    (define-key map (kbd "<M-up>") 'syslog-move-previous-file)
    (define-key map "t" 'syslog-toggle-filenames)
    ;; XEmacs does not like the Alt bindings
    (if (string-match "XEmacs" (emacs-version)) t)
    map)
  "The local keymap for `syslog-mode'.")

;; simple-call-tree-info: DONE
(defvar syslog-number-suffix-start 1
  "The first number used as rotation suffix.")

;; simple-call-tree-info: DONE
(defun syslog-shell-command (command &optional sudop tostrings)
  "Execute a shell COMMAND synchronously, with prefix arg (SUDOP) run under sudo.
If TOSTRINGS is non-nil then output will be returned as a list of strings (one per line),
otherwise it will be place in the *Shell Command Output* buffer."
  (interactive (list (read-shell-command (if current-prefix-arg
					     "Shell command (root): "
					   "Shell command: "))
		     current-prefix-arg))
  (with-temp-buffer
    (when sudop
      (cd (concat "/sudo::"
		  (replace-regexp-in-string
		   "^/sudo[^/]+" "" default-directory))))
    (if tostrings
	(split-string (shell-command-to-string command) "\n" t)
      (shell-command command))))



;; simple-call-tree-info: DONE
(defun syslog-get-basename-and-number (filename)
  "Return the basename and number suffix of a log file in FILEPATH.
Return results in a cons cell '(basename . number) where basename is a string,
and number is a number."
  (let* ((res (string-match "\\(.*?\\)\\.\\([0-9]+\\)\\(\\.t?gz\\)?" filename))
         (basename (if res (match-string 1 filename) filename))
         (str (and res (match-string 2 filename)))
         (num (or (and str (string-to-number str)) (1- syslog-number-suffix-start))))
    (cons basename num)))

;; simple-call-tree-info: DONE
(defun syslog-get-filenames (&optional pairs prompt onlyone)
  "Get log files associated with PAIRS argument, or prompt user for files.
The PAIRS argument should be a list of cons cells whose cars are paths to log files,
and whose cdrs are numbers indicating how many previous log files (if positive) or days 
 (if negative) to include. If PAIRS is missing then the user is prompted for those values.
If ONLYONE is non-nil then the user is only prompted for a single file.
The PROMPT argument is an optional prompt to use for prompting the user for files."
  (let* ((continue t)
	 (num 0)
	 (pairs
	  (or pairs
	      (cl-loop
	       while continue
	       do (setq
		   filename
		   (ido-read-file-name
		    (or prompt "Log file: ")
		    syslog-log-file-directory "syslog" nil)
		   num (if onlyone 0
			 (read-number
			  "Number of previous files (if positive) or days (if negative) to include"
			  num)))
	       collect (cons filename num)
	       if onlyone do (setq continue nil)
	       else do (setq continue (y-or-n-p "Add more files? "))))))
    (cl-remove-duplicates
     (cl-loop for pair1 in pairs
	      for filename = (car pair1)
	      for num = (cdr pair1)
	      for pair = (syslog-get-basename-and-number filename)
	      for basename = (car pair)
	      for basename2 = (file-name-nondirectory basename)
	      for curver = (cdr pair)
	      for num2 = (if (>= num 0) num
			   (- (let* ((startdate (+ (float-time (nth 5 (file-attributes filename)))
						   (* num 86400))))
				(cl-loop for file2 in (directory-files (file-name-directory filename)
								       t basename2)
					 for filedate2 = (float-time (nth 5 (file-attributes file2)))
					 if (>= filedate2 startdate)
					 maximize (cdr (syslog-get-basename-and-number file2))))
			      curver))
	      for files = (cl-loop for n from (1+ curver) to (+ curver num2)
				   for numstr = (number-to-string n)
				   for nextfile = (cl-loop for suffix in '(nil ".gz" ".tgz")
							   for filename3 = (concat basename "." numstr suffix)
							   if (file-readable-p filename3)
							   return filename3)
				   collect nextfile)
	      nconc (nconc (list filename) (cl-remove-if 'null files))) :test 'equal)))

;; simple-call-tree-info: DONE
(defun syslog-append-files (files buf &optional replace)
  "Append FILES into buffer BUF.
If REPLACE is non-nil then the contents of BUF will be overwritten.
When called interactively the current buffer is used, FILES are prompted for
using `syslog-get-filenames', and REPLACE is set to nil, unless
a prefix argument is used in which case they are prompted for."
  (interactive (list (syslog-get-filenames nil "Append log file: ")
		     (current-buffer)
		     (if current-prefix-arg
			 (y-or-n-p "Replace current buffer contents? "))))
  (with-current-buffer buf
    (let ((inhibit-read-only t))
      (set-visited-file-name nil)
      (save-excursion
	(cl-loop for file in (cl-remove-duplicates files :test 'equal)
		 do (goto-char (point-max))
		 (let ((start (point)))
		   (insert-file-contents file)
		   (goto-char (point-max))
		   (put-text-property start (point) 'syslog-filename file)))))))

;; simple-call-tree-info: DONE
(defun syslog-prepend-files (files buf &optional replace)
  "Prepend FILES into buffer BUF.
If REPLACE is non-nil then the contents of BUF will be overwritten.
When called interactively the current buffer is used, FILES are prompted for
using `syslog-get-filenames', and REPLACE is set to nil, unless
a prefix argument is used in which case they are prompted for."
  (interactive (list (syslog-get-filenames nil "Prepend log file: ")
		     (current-buffer)
		     (if current-prefix-arg
			 (y-or-n-p "Replace current buffer contents? "))))
  (with-current-buffer buf
    (let ((inhibit-read-only t))
      (set-visited-file-name nil)
      (cl-loop for file in (cl-remove-duplicates files :test 'equal)
	       do (let ((start (goto-char (point-min))))
		    (forward-char (cl-second (insert-file-contents file)))
		    (put-text-property start (point) 'syslog-filename file))))))

;; simple-call-tree-info: DONE
(defun syslog-create-buffer (filenames)
  "Create a new buffer named after the files in FILENAMES."
  (let* ((uniquefiles (mapcar 'file-name-nondirectory
			      (cl-remove-duplicates filenames :test 'equal)))
	 (basenames (mapcar (lambda (x)
			      (replace-regexp-in-string
			       "\\(\\.gz\\|\\.tgz\\)$" ""
			       (file-name-nondirectory x)))
			    uniquefiles))
	 (basenames2 (cl-remove-duplicates
		      (mapcar (lambda (x) (replace-regexp-in-string "\\.[0-9]+$" "" x)) basenames)
		      :test 'equal)))
    (get-buffer-create
     (substring (cl-loop for file in basenames2
			 for files = (cl-remove-if-not
				      (lambda (x) (string-match-p (regexp-opt (list file)) x))
				      basenames)
			 for nums = (mapcar (lambda (x)
					      (let* ((match (string-match "\\.\\([0-9]+\\)" x))
						     (n (if match (match-string 1 x) "0")))
						(string-to-number n)))
					    files)
			 for min = (if nums (apply 'min nums) 0)
			 for max = (if nums (apply 'max nums) 0)
			 concat (concat file "." (if (= min max) (number-to-string min)
						   (concat "{" (number-to-string min)
							   "-" (number-to-string max) "}"))
					","))
		0 -1))))

;; simple-call-tree-info: DONE
(defun syslog-open-files (files &optional label)
  "Insert log FILES into new buffer, and switch to that buffer.
If the optional argument LABEL is non-nil then each new line will be labelled
with the corresponding filename.
When called interactively the FILES are prompted for using `syslog-get-filenames'."
  (interactive (list (syslog-get-filenames nil "View log file: ")
		     (y-or-n-p "Label lines with filenames? ")))
  (let ((buf (syslog-create-buffer files)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
	(set-visited-file-name nil)
	(cl-loop for file in (cl-remove-duplicates files :test 'equal)
		 do (let ((start (goto-char (point-max))))
		      (insert-file-contents file)
		      (goto-char (point-max))
		      (unless (not label)
			(forward-line 0)
			(goto-char
			 (apply-on-rectangle
			  'string-rectangle-line start (point)
			  (concat (file-name-nondirectory file) ": ") nil)))
		      (put-text-property
		       start (point) 'syslog-filename file))))
      (syslog-mode)
      (setq default-directory (file-name-directory (car files))))
    (switch-to-buffer buf)))

;;;###autoload
;; simple-call-tree-info: CHECK
(defun syslog-view (files &optional label treatments rxshowstart rxshowend
			  rxhidestart rxhideend startdate enddate removedates
			  highlights bufname)
  "Open a view of syslog files with optional filters and highlights applied.
When called interactively the user is prompted for a member of `syslog-views' and the
arguments are determined from the chosen member.
FILES can be either nil in which case the view is applied to the current log file, or
it can be the same as the first argument to `syslog-get-filenames' - a list of cons
cells whose cars are filenames and whose cdrs indicate how many logfiles to include.
LABEL indicates whether or not to label each line with the filename it came from.
RXSHOWSTART, RXSHOWEND and RXHIDESTART, RXHIDEEND are optional regexps which will be 
used to filter in/out blocks of buffer lines with `syslog-filter-lines'. 
STARTDATE and ENDDATE are optional dates used to filter the lines with `syslog-filter-dates'; 
they can be either date strings or time lists as returned by `syslog-date-to-time'.
HIGHLIGHTS is a list of cons cells whose cars are regexps and whose cdrs are faces to 
highlight those regexps with."
  (interactive (cdr (cl-assoc (ido-completing-read "View: " (mapcar 'car syslog-views))
			      syslog-views :test 'string=)))
  (cl-flet ((getstr (str) (and (not (string= str "")) str)))
    (let ((rxshowstart (getstr rxshowstart))
	  (rxshowend (getstr rxshowend))
	  (rxhidestart (getstr rxhidestart))
	  (rxhideend (getstr rxhideend))
	  (startdate (getstr startdate))
	  (enddate (getstr enddate))
	  (bufname (getstr bufname))) 
      (when files (syslog-open-files (syslog-get-filenames files) label))
      (if (not (eq major-mode 'syslog-mode))
	  (error "Not in syslog-mode")
	(dolist (trt treatments)
	  (cond ((and (consp trt)
		      (functionp (car trt)))
		 (let* ((args1 (cdadr (interactive-form (car trt))))
			(args2 (cdr trt))
			(args3 (cl-loop
				for arg in args1
				for i from 0
				for arg2 = (nth i args2)
				collect (if (eq (eval arg2) 'interactive)
					    (eval arg)
					  arg2))))
		   (apply (car trt) args3)))
		((and (consp trt)
		      (stringp (car trt)))
		 (save-excursion
		   (goto-char (point-min))
		   (while (re-search-forward (car trt) nil t)
		     (replace-match (if (functionp (cdr trt))
					(funcall (cdr trt) (match-string 1))
				      (cdr trt))
				    t nil nil 1))))
		(t (error "Invalid treatments arg"))))
	(if rxshowstart
	    (if rxshowend
		(hide-blocks-not-matching rxshowstart rxshowend)
	      (hide-lines-not-matching rxshowstart)))
	(if rxhidestart
	    (if rxhideend
		(hide-blocks-not-matching rxhidestart rxhideend)
	      (hide-lines-matching rxhidestart)))
	(if (or startdate enddate)
	    (syslog-filter-dates startdate enddate removedates))
	(if highlights
	    (cl-loop for hl in highlights
		     for (regex . face) = hl
		     do (highlight-regexp regex face)))
	(if bufname (rename-buffer bufname t))))))

;; simple-call-tree-info: DONE
(defun syslog-previous-file (&optional arg)
  "Open the previous logfile backup, or the next one if a prefix arg is used.
Unix systems keep backups of log files with numbered suffixes, e.g. syslog.1 syslog.2.gz, etc.
where higher numbers indicate older log files.
This function will load the previous log file to the current one (if it exists), or the next
one if ARG is non-nil."
  (interactive "P")
  (let* ((pair (syslog-get-basename-and-number
		(syslog-get-filename-at-point)))
         (basename (car pair))
         (curver (cdr pair))
         (nextver (if arg (1- curver) (1+ curver)))
         (nextfile (if (> nextver (1- syslog-number-suffix-start))
                       (concat basename "." (number-to-string nextver))
                     basename)))
    (let ((inhibit-read-only t))
      (cond ((file-readable-p nextfile)
	     (find-file nextfile))
	    ((file-readable-p (concat nextfile ".bz2"))
	     (find-file (concat nextfile ".bz2")))
	    ((file-readable-p (concat nextfile ".gz"))
	     (find-file (concat nextfile ".gz")))
	    ((file-readable-p (concat nextfile ".tgz"))
	     (find-file (concat nextfile ".tgz"))))
      (put-text-property (point-min) (point-max) 'syslog-filename nextfile))))

;; simple-call-tree-info: DONE
(defun syslog-next-file nil
  "Open the next logfile.
This just calls `syslog-previous-file' with non-nil argument, so we can bind it to a key."
  (interactive)
  (syslog-previous-file t))

;; simple-call-tree-info: DONE
(defun syslog-move-next-file (&optional arg)
  "Move to the next file in the current `syslog-mode' buffer.
If ARG is non-nil (or called with numeric prefix arg), move that many
files forward."
  (interactive "p")
  (cl-loop for i from 1 to arg
	   do (goto-char (next-single-property-change
			  (point) 'syslog-filename nil (point-max)))))

;; simple-call-tree-info: DONE
(defun syslog-move-previous-file (&optional arg)
  "Move to the next file in the current `syslog-mode' buffer.
If ARG is non-nil (or called with numeric prefix arg), move that many
files forward."
  (interactive "p")
  (cl-loop for i from 1 to arg
	   do (goto-char (previous-single-property-change
			  (point) 'syslog-filename nil (point-min)))))

;; simple-call-tree-info: DONE
(defun syslog-get-filename-at-point nil
  "Get the filename associated with the line at point."
  (or (get-text-property (point) 'syslog-filename)
      buffer-file-name))

;; simple-call-tree-info: DONE
(defun syslog-toggle-filenames (&optional arg)
  "Toggle the display of filenames before each line.
If prefix ARG is positive display filenames, and if its negative hide them,
otherwise toggle them."
  (interactive "P")
  (save-excursion
    (ov-set (ov-in) 'invisible nil)
    (let* ((start (goto-char (point-min)))
	   (filename (syslog-get-filename-at-point))
	   (fileshownp (and filename
			    (looking-at
			     (concat "^" (regexp-quote (file-name-nondirectory filename))
				     ": "))))
	   (hidep (if arg (prefix-numeric-value arg) 0)))
      (let ((inhibit-read-only t))
	(while (and (goto-char
		     (next-single-property-change
		      (point) 'syslog-filename nil (point-max)))
		    (/= start (point)))
	  (if fileshownp
	      (if (<= hidep 0)
		  (apply-on-rectangle
		   'delete-rectangle-line
		   start (+ (line-beginning-position 0)
			    (length (match-string 0)))
		   nil))
	    (unless (< hidep 0)
	      (apply-on-rectangle
	       'string-rectangle-line start
	       (line-beginning-position 0)
	       (concat (file-name-nondirectory filename) ": ")
	       nil)
	      (put-text-property start (point) 'syslog-filename filename)))
	  (setq start (point)
		filename (syslog-get-filename-at-point)
		fileshownp (and filename
				(looking-at
				 (concat "^" (regexp-quote (file-name-nondirectory filename))
					 ": ")))))))
    (ov-set (ov-in) 'invisible 'hl)))

;;;###autoload
;; simple-call-tree-info: DONE
(defun syslog-filter-lines (&optional arg)
  "Restrict buffer to blocks of text between matching regexps.
If the user only enters one regexp then just filter matching lines instead of blocks.
With prefix ARG: remove matching blocks."
  (interactive "p")
  (let* ((str (if (> arg 1) "to remove" "to keep"))
	 (startregex (read-regexp
		      (format "Regexp matching start lines of blocks %s" str)
		      (symbol-name (symbol-at-point))))
	 (endregex (read-regexp
		    (format "Regexp matching end lines of blocks %s (default=filter start lines only)" str)))
	 (n (length (overlays-in (point-min) (point-max)))))
    (unless (string= startregex "")
      (if (> arg 1)
	  (if (string= endregex "")
	      (hide-lines-matching startregex)
	    (hide-blocks-matching startregex endregex))
	(if (string= endregex "")
	    (hide-lines-not-matching startregex)
	  (hide-blocks-not-matching startregex endregex)))
      (if (= n (length (overlays-in (point-min) (point-max))))
	  (message "No matches found")))))

;; simple-call-tree-info: TODO  allow more faces?
(cl-defun highlight-regexp-unique (regexp &optional (facerx nil) faces)
  "Highlight each unique string matched by REGEXP with a different face.
Interactively, prompt for REGEXP using `read-regexp', and prompt for a
subset of FACES (default `syslog-hi-face-default') to use for highlighting either:
 \"foreground\" (faces that change the foreground colour),
 \"background\" (faces that change the background colour), 
 or \"choose\" to specify a regexp (FACERX) to match the face names. 
If a prefix arg is used then only the \"choose\" option is available,
and the specified regexp will be used to filter all defined faces.
When called non-interactively, faces can be either a list of faces, nil for
the default value (`syslog-hi-face-default'), or any other value for all defined 
faces.

If REGEXP contains non-shy match groups, then only those parts of the
match will be treated as unique strings & highlighted (rather than the whole regexp).
In this case overlays will always be used (which can be slow if there are many matches).
If there are no non-shy match groups, and `font-lock-mode' is enabled then 
that will be used for doing the highlighting."
  (interactive
   (list (hi-lock-regexp-okay
	  (read-regexp "Regexp to highlight" 'regexp-history-last))
	 (let ((choice (if current-prefix-arg
			   "choose"
			 (completing-read
			  "Highlight type: " '("background" "foreground" "choose")))))
	   (cond ((equal choice "background") "-[^b]\\|[^-].")
		 ((equal choice "foreground") "-b$")
		 ((equal choice "choose")
		  (read-regexp "Regexp matching face names to use (default \".*\"): "
			       ".*"))))
	 (if current-prefix-arg (face-list) syslog-hi-face-defaults)))
  (unless hi-lock-mode (hi-lock-mode 1))
  (let* ((facerx (or facerx ".*"))
	 (faces (cond ((null faces) syslog-hi-face-defaults)
		      ((listp faces) faces)
		      (t (face-list))))
	 (unused-faces (set-difference
			(if (> (length facerx) 0)
			    (cl-remove-if-not
			     (lambda (f) (string-match facerx (symbol-name f)))
			     faces)
			  faces)
			(mapcar (lambda (p) (eval (cadadr p)))
				hi-lock-interactive-patterns)))
	 (matchrx "[^(]*\\\\(\\(.*?\\)\\\\)"))
    (cl-flet ((repmatch (i) (let (ss)
			      (while (> i 0)
				(setq ss (cons matchrx ss))
				(setq i (1- i)))
			      (apply 'concat ss))))
      (cl-loop for pair in (syslog-unique-matches regexp)
	       for face in unused-faces
	       do (let* ((match (car pair))
			 (i (cadr pair)))
		    (hi-lock-set-subpattern
		     (if (> i 0)
			 (replace-regexp-in-string
			  (if (> i 1) (repmatch i) matchrx)
			  (regexp-quote match) regexp t t i)
		       (regexp-quote match))
		     face i))))))

;; simple-call-tree-info: DONE (tweaked version of `hi-lock-set-pattern')
(defun hi-lock-set-subpattern (regexp face subx)
  "Highlight the SUBX match group of REGEXP with face FACE."
  ;; Hashcons the regexp, so it can be passed to remove-overlays later.
  (setq regexp (hi-lock--hashcons regexp))
  (let ((pattern (list regexp (list 0 (list 'quote face) 'prepend))))
    ;; Refuse to highlight a text that is already highlighted.
    (unless (assoc regexp hi-lock-interactive-patterns)
      (push pattern hi-lock-interactive-patterns)
      (if (and font-lock-mode (font-lock-specified-p major-mode)
	       (= subx 0))
	  (progn
	    (font-lock-add-keywords nil (list pattern) t)
	    (font-lock-flush))
        (let* ((range-min (- (point) (/ hi-lock-highlight-range 2)))
               (range-max (+ (point) (/ hi-lock-highlight-range 2)))
               (search-start
                (max (point-min)
                     (- range-min (max 0 (- range-max (point-max))))))
               (search-end
                (min (point-max)
                     (+ range-max (max 0 (- (point-min) range-min))))))
          (save-excursion
            (goto-char search-start)
            (while (re-search-forward regexp search-end t)
              (let ((overlay (make-overlay (match-beginning subx) (match-end subx))))
                (overlay-put overlay 'hi-lock-overlay t)
                (overlay-put overlay 'hi-lock-overlay-regexp regexp)
                (overlay-put overlay 'face face))
              (goto-char (match-end 0)))))))))

;;;###autoload
;; simple-call-tree-info: DONE
(defcustom syslog-views nil
  "A list of views.
Each view is a list of:
 - a name for the view
 - a list of files to display; each item in the list is a cons cell whose car is the base log file, 
     and whose cdr is a number indicating how many previous log files of the same type to include.
     If nil then the view will be applied to the currently displayed file.
 - a boolean indicating whether or not to label each line with the filename
 - an optional list of functions to apply to transform the buffer before filtering & highlighting. 
     Each element is either:
     - a list whose car is a function and whose cdr is a list of arguments for the function. The arglist
       may contain the symbol 'interactive which means the value will be prompted for when the view is invoked.
     - a cons cell whose car is a regexp containing a match group, and whose cdr is either a replacement
       string, or a function that takes the text captured by that match group as its only arg, and returns 
       some text to replace it. This function/string will be used for replacing all matches in the buffer.
 - a regexp matching start lines of blocks to show
 - a regexp matching end lines of blocks to show (if blank then lines will be filtered instead of blocks)
 - a regexp matching start lines of blocks to hide
 - a regexp matching end lines of blocks to hide (if blank then lines will be hidden instead of blocks)
 - an optional start date for filtering lines with `syslog-filter-dates'
 - an optional end date for filtering lines with `syslog-filter-dates'
 - a boolean; if non-nil hide lines matching above dates, otherwise display only those lines
 - a list of highlighting info; each element is a cons cell whose car is a regexp to highlight and 
   whose cdr is a face to use for highlighting
 - an optional name to rename the buffer"
  :group 'syslog
  :type '(repeat (list (string :tag "Name")
		       (repeat :tag "File(s)"
			       (cons (string :tag "Base file")
				     (number :tag "Number of previous files/days")))
		       (choice (const :tag "No file labels" nil)
			       (const :tag "Add file labels" t))
		       (repeat :tag "Treatment(s)"
			       (choice (cons :tag "Apply function"
					     (function :tag "Function")
					     (repeat
					      :tag "Args"
					      (choice :tag "Arg"
						      (sexp)
						      (const :tag "Prompt user when view is invoked"
							     'interactive))))
				       (cons :tag "Replace string"
					     (regexp
					      :help-echo "Regexp containing a match group"
					      :validate
					      (lambda (w)
						(let ((v (widget-value w)))
						  (when (< (regexp-opt-depth v) 1)
						    (widget-put
						     w :error
						     "Regexp must have at least one match group")
						    w))))
					     (choice (function
						      :help-echo
						      "Function of one argument (a string captured by regexp match group)")
						     (string :help-echo "Replacement string")))))
		       (regexp :tag "Regexp matching start lines of blocks to show")
		       (regexp :tag "Regexp matching end lines of blocks to show")
		       (regexp :tag "Regexp matching start lines of blocks to hide")
		       (regexp :tag "Regexp matching end lines of blocks to hide")
		       (string :tag "Start date")
		       (string :tag "End date")
		       (choice (const :tag "Keep matching dates" nil)
			       (const :tag "Remove matching dates" t))
		       (repeat :tag "Highlights"
			       (cons (regexp :tag "Regexp to highlight")
				     (face :tag "Face")))
		       (string :tag "Buffer name"))))

;; simple-call-tree-info: DONE
(defcustom syslog-datetime-regexp
  "^\\(?:[^ :]+: \\)?\\(\\(?:\\(?:[[:alpha:]]\\{3\\}\\)?[[:space:]]*[[:alpha:]]\\{3\\}\\s-+[0-9]+\\s-+[0-9:]+\\)\\|\\(?:[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\s-+[0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\}\\)\\)"
  "A regular expression matching the date-time at the beginning of each line in the log file.
It should contain one non-shy subexpression matching the datetime string."
  :group 'syslog
  :type 'regexp)

;; simple-call-tree-info: DONE
(defcustom syslog-log-file-directory "/var/log/"
  "The directory in which log files are stored."
  :group 'syslog
  :type 'directory)

;; Add some extra faces for highlighting
;; simple-call-tree-info: CHECK
(defface hi-red
  '((((background dark)) (:background "red" :foreground "black"))
    (t (:background "red")))
  "Face for hi-lock mode."
  :group 'hi-lock-faces)
(defface hi-yellow-b
  '((((min-colors 88)) (:weight bold :foreground "yellow"))
    (t (:weight bold :foreground "yellow")))
  "Face for hi-lock mode."
  :group 'hi-lock-faces)
(defface hi-pink-b
  '((((min-colors 88)) (:weight bold :foreground "pink"))
    (t (:weight bold :foreground "pink")))
  "Face for hi-lock mode."
  :group 'hi-lock-faces)

;; simple-call-tree-info: CHECK
(defcustom syslog-hi-face-defaults '(hi-red hi-blue hi-green hi-yellow hi-pink
					    hi-red-b hi-blue-b hi-green-b hi-yellow-b
					    hi-pink-b hi-black-b hi-black-hb)
  "List of faces (as symbols) to use for automatic highlighting."
  :group 'syslog
  :type '(repeat (string :tag "Face")))

;;;###autoload
;; simple-call-tree-info: DONE
(cl-defun syslog-date-to-time (date &optional safe)
  "Convert DATE string to time.
If no year is present in the date then the current year is used.
If DATE can't be parsed then if SAFE is non-nil return nil otherwise throw an error."
  (if safe
      (let ((time (safe-date-to-time (concat date " " (substring (current-time-string) -4)))))
	(if (and (= (car time) 0) (= (cdr time) 0))
	    nil
	  time))
    (date-to-time (concat date " " (substring (current-time-string) -4)))))

;;;###autoload
;; simple-call-tree-info: DONE
(defun syslog-filter-dates (start end &optional arg)
  "Restrict buffer to lines between times START and END (Emacs time lists).
With prefix ARG: remove lines between dates.
If either START or END are nil then treat them as the first/last time in the
buffer respectively."
  (interactive (let (firstdate lastdate)
                 (save-excursion
                   (goto-char (point-min))
                   (beginning-of-line)
                   (re-search-forward syslog-datetime-regexp nil t)
                   (setq firstdate (match-string 1))
                   (goto-char (point-max))
                   (beginning-of-line)
                   (re-search-backward syslog-datetime-regexp nil t)
                   (setq lastdate (match-string 1)))
                 (list (syslog-date-to-time (read-string "Start date and time: "
                                                         firstdate nil firstdate))
                       (syslog-date-to-time (read-string "End date and time: "
                                                         lastdate nil lastdate))
		       current-prefix-arg)))
  (let ((start (if (stringp start)
		   (syslog-date-to-time start)
		 start))
	(end (if (stringp end)
		 (syslog-date-to-time end)
	       end)))
    (set (make-local-variable 'line-move-ignore-invisible) t)
    (goto-char (point-min))
    (let* ((start-position (point-min))
	   (pos (re-search-forward syslog-datetime-regexp nil t))
	   (intime-p (lambda (time)
		       (let ((isin (and (or (not end) (time-less-p time end))
					(or (not start) (not (time-less-p time start))))))
			 (and time (if arg (not isin) isin)))))
	   (keeptime (funcall intime-p (syslog-date-to-time (match-string 1) t)))
	   (dodelete t))
      (while pos
	(cond ((and keeptime dodelete)
	       (hide-lines-add-overlay start-position (point-at-bol))
	       (setq dodelete nil))
	      ((not (or keeptime dodelete))
	       (setq dodelete t start-position (point-at-bol))))
	(setq pos (re-search-forward syslog-datetime-regexp nil t)
	      keeptime (funcall intime-p (syslog-date-to-time (match-string 1) t))))
      (if dodelete (hide-lines-add-overlay start-position (point-max))))))

;;;###autoload
;; simple-call-tree-info: DONE
(defun syslog-mode ()
  "Major mode for working with system logs.

\\{syslog-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (setq mode-name "syslog")
  (setq major-mode 'syslog-mode)
  (use-local-map syslog-mode-map)
  ;; Menu definition
  (easy-menu-define nil syslog-mode-map "test"
    `("Syslog"
      ["Quit" quit-window :help "Quit and bury this buffer" :key "q"]
      ["Revert buffer" revert-buffer :help "View the function at point" :key "R"]
      ["Show all"  hide-lines-show-all :help "Show all hidden lines/blocks" :key "g"]
      ["Filter lines..." syslog-filter-lines :help "Show/hide blocks of text between matching regexps" :key "/"]
      ["Filter dates..." syslog-filter-dates :help "Show/hide lines between start and end dates" :key "C-/"]
      ["Kill hidden" hide-lines-kill-hidden :help "Kill (with prefix delete) hidden lines" :key "k"]
      ["Jump to boot start" syslog-boot-start :help "Jump forward in the log to when the system booted" :key "<C-down>"]
      ["Open previous log file" syslog-previous-file :help "Open previous logfile backup" :key "<"]
      ["Open next log file" syslog-next-file :help "Open next logfile backup" :key ">"]
      ["Move to previous log file" syslog-move-previous-file :help "Move to previous logfile in buffer" :key "<M-up>"]
      ["Move to next log file" syslog-move-next-file :help "Move to next logfile in buffer" :key "<M-down>"]
      ["Open log files..." syslog-open-files :help "Insert log files into new buffer" :key "o"]
      ["Append files..." syslog-append-files :help "Append files into current buffer" :key "a"]
      ["Prepend files..." syslog-prepend-files :help "Prepend files into current buffer" :key "p"]
      ["Toggle filenames" syslog-toggle-filenames :help "Toggle display of filenames" :key "t"]
      ["Find file at point" ffap :help "Find file at point" :key "f"]
      ["Whois" syslog-whois-reverse-lookup :help "Perform whois lookup on hostname at point" :key "W"]
      ["Count matches" syslog-count-matches :help "Count strings which match the given pattern" :key "c"]
      ["Extract matches" syslog-extract-matches :help "Extract & concatenate strings which match the given pattern" :key "x"]
      ["Dired" (lambda nil (interactive) (dired syslog-log-file-directory)) :help "Enter logfiles directory" :keys "D"]
      ["Shell command" syslog-shell-command :help "Execute shell command (as root if prefix arg used)" :key "!"]
      ["Highlight..." (keymap "Highlight"
			      (regexp menu-item "Regexp" highlight-regexp
				      :help "Highlight each match of regexp"
				      :keys "h r")
			      (phrase menu-item "Phrase" highlight-phrase
				      :help "Highlight each match of phrase"
				      :keys "h p")
			      (lines menu-item "Lines matching regexp" highlight-lines-matching-regexp
				     :help "Highlight lines containing match of regexp"
				     :keys "h l")
			      (unhighlight menu-item "Unhighlight regexp" unhighlight-regexp
					   :help "Remove highlighting"
					   :keys "h u"))]
      ["Open stored view..." syslog-view :help "Open a stored view of syslog files" :key "v"]
      ["Edit stored views..." (lambda nil (interactive) (customize-variable 'syslog-views)) :help "Customize `syslog-views'"]
      ["---" "---"]))
  ;; font locking
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(syslog-font-lock-keywords t t nil ))
  (buffer-disable-undo)
  (toggle-read-only 1)
  (run-hooks 'syslog-mode-hook))

;; simple-call-tree-info: DONE
(defvar syslog-boot-start-regexp "unix: SunOS"
  "Regexp to match the first line of boot sequence.")

;; simple-call-tree-info: CHECK
(defun syslog-unique-matches (rx &optional ignorecase)
  "Find unique strings matching RX or it's non-shy match groups if it has any.
Return value is an alist whose car values are the unique matched strings,
and the cdr values are integers indicating the match group that the string
was matched with, or 0 if RX contains no non-shy match groups.
If optional argument IGNORECASE is non-nil then case will be ignored during
matching."
  (let ((ngrps (regexp-opt-depth rx))
	(case-fold-search ignorecase)
	matches)
    (cl-flet ((addmatch (m i)
			(let ((pair (assoc m matches)))
			  (if pair
			      (when (not (memq i (cdr pair)))
				(setf (cdr pair) (cons i (cdr pair))))
			    (add-to-list
			     'matches
			     (cons (substring-no-properties m)
				   (list i)))))))
      (save-excursion
	(goto-char (point-min))
	(if (> ngrps 0)
	    (while (re-search-forward rx nil t)
	      (cl-loop for i from 1
		       for match = (match-string i)
		       if match do (addmatch match i)
		       else return nil))
	  (while (re-search-forward rx nil t)
	    (addmatch (match-string 0) 0)))))
    matches))

;; simple-call-tree-info: DONE
(defun syslog-count-matches (rx &optional display ignorecase)
  "Count all matches to regexp RX in current buffer.
If RX contains non-shy match groups then matches to them will
be counted, otherwise matches to the whole regexp will be counted.
If DISPLAY is non-nil or if called interactively then the counts
will be displayed in the minibuffer, otherwise an alist of (string . count)
pairs will be returned.
If IGNORECASE is non-nil or when called interactively with a prefix arg
case will be ignored when searching for matches."
  (interactive (list (read-regexp
		      "Regexp: "
		      '("^[0-9]+" "pid=\"\\([^ ]+\\)\""))
		     t current-prefix-arg))
  (let ((ngrps (regexp-opt-depth rx))
	(case-fold-search ignorecase)
	matches)
    (cl-flet ((addmatch (m)
			(let ((pair (assoc m matches)))
			  (if pair
			      (setf (cdr pair) (1+ (cdr pair)))
			    (add-to-list
			     'matches
			     (cons (substring-no-properties m) 1))))))
      (save-excursion
	(goto-char (point-min))
	(if (> ngrps 0)
	    (while (re-search-forward rx nil t)
	      (cl-loop for i from 1
		       for match = (match-string i)
		       if match do (addmatch match)
		       else return nil))
	  (while (re-search-forward rx nil t)
	    (addmatch (match-string 0))))))
    (setq matches (sort matches (lambda (a b) (> (cdr a) (cdr b)))))
    (if display
	(cl-format t "~:{~a:~s ~}" matches)
      matches)))

;; simple-call-tree-info: TODO
(defun syslog-extract-matches (rx &optional sep count outbuf overwrite)
  "Extract & concatenate strings matching regexp RX (or its match groups).
Separate the matches with SEP if non-nil. If COUNT is non-nil then only collect
the first COUNT matches. When called interactively the extracted strings will be printed
to the *Syslog extract* buffer, otherwise a buffer or buffer name can be supplied in OUTBUF.
If OUTBUF is nil then the extract will be returned as a string.
If OVERWRITE is non-nil then the buffer will be overwritten otherwise it will be appended to."
  (interactive (list (read-regexp "Regexp matching strings to collect: "
				  '("\"\\([^\"]*\\)\""))
		     (read-string "Separator: ")
		     (when current-prefix-arg
		       (prefix-numeric-value current-prefix-arg))
		     (get-buffer-create "*Syslog extract*")
		     (when (with-current-buffer (get-buffer "*Syslog extract*")
			     (goto-char (point-min))
			     (re-search-forward "\\S-" nil t))
		       (y-or-n-p "Overwrite existing text in *Syslog extract* buffer"))))
  (let ((ngrps (regexp-opt-depth rx))
	str)
    (cl-flet ((addmatch (m) (setq str (concat str sep (substring-no-properties m)))
			(when count (setq count (1- count)))))
      (save-excursion
	(if (> ngrps 0)
	    (while (and (re-search-forward rx nil t)
			(or (not count) (> count 0)))
	      (cl-loop for i from 1
		       for match = (match-string i)
		       if match do (addmatch match)
		       else return nil))
	  (while (and (re-search-forward rx nil t)
		      (or (not count) (> count 0)))
	    (addmatch (match-string 0))))))
    (if (not outbuf)
	str
      (with-current-buffer outbuf
	(when overwrite
	  (delete-region (point-min) (point-max)))
	(goto-char (point-max))
	(insert "\n" str))
      (when (called-interactively-p 'any)
	(display-buffer outbuf)))))

;; simple-call-tree-info: DONE
(defun syslog-boot-start ()
  "Jump forward in the log to when the system booted."
  (interactive)
  (search-forward-regexp syslog-boot-start-regexp (point-max) t)
  (beginning-of-line))

;; simple-call-tree-info: DONE
(defun syslog-whois-reverse-lookup (arg search-string)
  "This is a wrapper around the `whois' command using symbol at point as default search string.
Also `whois-server-name' is set to `whois-reverse-lookup-server'.
The ARG and SEARCH-STRING arguments are the same as for `whois'."
  (interactive (list current-prefix-arg
		     (let* ((symb (symbol-at-point))
			    (default (replace-regexp-in-string ":[0-9]+$" "" (symbol-name symb))))
		       (read-string (if symb (concat "Whois (default " default "): ")
				      "Whois: ") nil nil default))))
  (let ((whois-server-name whois-reverse-lookup-server))
    (whois arg search-string)))

;; simple-call-tree-info: DONE
(cl-defun syslog-lsof (&optional (pids nil) (filtercmd nil)
				 (sudop nil) (flags "-n -P -L -E"))
  "Return list of strings containing lines of output from lsof command.
PIDS is either a list of integers, or a single string which will be passed to
the -p option to lsof to limit the output to certain process IDs (if nil then no such 
limiting takes place).
FILTERCMD is an optional shell command to process the output of lsof (e.g. \"grep ' FIFO '\").
SUDOP indicates whether to run lsof under sudo or not.
FLAGS is a list of flags for lsof, and is set to \"-n -P -L -E\" by default."
  (interactive (list (read-string "Comma separated list of PIDs &/or their negations (e.g. \"123,^456\"): ")
		     (read-string "Optional filter command (e.g. \"grep ' FIFO '\"): "
				  nil nil '("grep ' FIFO '"))
		     current-prefix-arg
		     (read-string "Flags for lsof: " "-n -P -L -E")))
  (let ((output (syslog-shell-command (concat "lsof " flags 
					      (when pids
						(concat " -p"
							(cond
							 ((stringp pids) pids)
							 ((listp pids)
							  (mapconcat 'number-to-string pids ","))
							 (t (error "Invalid PIDS arg")))))
					      (when (and filtercmd (> (length filtercmd) 0))
						(concat " | " filtercmd)))
				      sudop (not (called-interactively-p 'any)))))
    (when (called-interactively-p 'any)
      (with-current-buffer "*Shell Command Output*"
	(rename-buffer "*lsof output*" t)))
    output))

;; simple-call-tree-info: CHECK
(defun syslog-lsof-get-pipes (lsof)
  "Return info about unix pipes from LSOF output.
Pipe info will be extracted from the buffer, file or lines supplied the LSOF arg.
The return value is a list of lists, each containing info about a particular pipe.
The first element of each list is a string containing the inode for the pipe, 
and subsequent elements contain pipe endpoint info as returned by the lsof command.
See the lsof manpage for more info."
  (let* ((lines (cl-remove-if-not
		 (lambda (l) (string-match " FIFO " l))
		 (let* ((lns (if (listp lsof)
				 lsof
			       (split-string
				(with-current-buffer
				    (if (stringp lsof)
					(find-file-noselect lsof)
				      lsof)
				  (buffer-substring-no-properties
				   (point-min) (point-max)))
				"\n" t)))
			(ln1 (split-string (car lns) " " t)))
		   ;; check that lsof output has required columns
		   (unless (and (string= (nth 7 ln1) "NODE")
				(string= (nth 8 ln1) "NAME"))
		     (error "Invalid format for lsof output"))
		   lns)))
	 (pipes (mapcar (lambda (l)
			  (let ((parts (split-string l "\s+")))
			    (cons (nth 7 parts) (nthcdr 9 parts)))) 
			lines))
	 pipes2)
    (cl-loop for p in pipes
	     for elem = (assoc (car p) pipes2)
	     for lst = (cdr elem)
	     if elem do (progn (dolist (p2 (cdr p))
				 (add-to-list 'lst p2))
			       (setcdr elem lst))
	     else do (add-to-list 'pipes2 p))
    pipes2))

;; simple-call-tree-info: DONE
(defun syslog-pid-to-comm (pid &optional lsof)
  "Return name of process associated with PID.
If LSOF is nil (default) the ps shell command will be used to find the process name,
which means it should be currently running. Otherwise LSOF should be either the path to 
a file or a buffer containing lsof output, or a list of lines of lsof output as returned 
by `syslog-lsof'. This lsof output will be used to find the process name.
If the process name cannot be determined then the pid will be returned as a string."
  (let* ((pid (cond ((integerp pid) (number-to-string pid))
		    ((stringp pid) pid)
		    (t (error "Invalid pid arg"))))
	 (pidrx (concat "^\\(\\S-+\\)\\s-+\\(" pid "\\)\\s-")))
    (cond ((or (bufferp lsof) (stringp lsof))
	   (with-current-buffer
	       (if (stringp lsof)
		   (find-file-noselect lsof)
		 lsof)
	     (save-excursion
	       (goto-char (point-min))
	       (if (re-search-forward pidrx nil t)
		   (match-string 1)
		 pid))))
	  ((null lsof)
	   (let ((str (shell-command-to-string
		       (concat "ps -p " pid " -o comm --no-headers"))))
	     (if (> (length str) 0)
		 (substring-no-properties str 0 -1)
	       pid)))
	  ((listp lsof)
	   (or (cl-loop for str in lsof
			if (string-match pidrx str)
			return (match-string 1 str))
	       pid)))))

;; simple-call-tree-info: CHECK
(defmacro syslog-alter-buffer (&rest forms)
  "Execute FORMS with `buffer-read-only' disabled then restore to its previous value.
If an error occurs while executing FORMS then `buffer-read-only' will be restored to 
it's previous value. Position of point will also be restored."
  `(let ((ro buffer-read-only))
     (save-excursion
       (condition-case err
	   (progn (setq buffer-read-only nil)
		  ,@forms
		  (setq buffer-read-only ro))
	 (error (setq buffer-read-only ro)
		(error "%s: %s" (car err) (cdr err)))))))

;; simple-call-tree-info: CHECK
(cl-defun syslog-replace-pids (pidrx &optional lsof)
  "Replace PIDs with process names in buffer, and return the list of process names.
PIDRX should be a regexp matching the pids or containing a non-shy match group for 
matching pids. The LSOF arg is interpreted in the same way as `syslog-pid-to-comm'.

When called interactively with no prefix arg, a file containing lsof output will be
prompted for, with a single prefix arg a buffer will be prompted for, otherwise the
ps shell command will be used to find process names.

Note: if PIDRX doesn't contain any non-shy group then it will be used for finding pids,
but any string matching the discovered pids (even in different locations to the match)
will be replaced. If you only want to do the replacements in the positions matched by 
PIDRX use a non-shy group to surround the pid."
  (interactive (list (read-regexp
		      "Regexp with match group for PID"
		      '("^[0-9]+" "pid=\\([0-9]+\\)"))
		     (cond ((equal current-prefix-arg '(4))
			    (get-buffer
			     (read-buffer "Buffer containing lsof output: " nil t)))
			   (current-prefix-arg nil)
			   (t (read-file-name "File containing lsof output: ")))))
  (let ((pids (mapcar 'car (syslog-unique-matches pidrx)))
	names)
    (syslog-alter-buffer
     (setq names
	   (mapcar (lambda (p)
		     (goto-char (point-min))
		     (let ((rx (if (< (regexp-opt-depth pidrx) 1)
				   p
				 (replace-regexp-in-string "\\\\(.*?\\\\)" p pidrx)))
			   (name (syslog-pid-to-comm p lsof)))
		       (replace-regexp rx name)
		       name))
		   pids)))
    names))

;; simple-call-tree-info: CHECK
(cl-defun syslog-replace-pipes (piperx lsof)
  "Replace pipe inode numbers with info about processes using the info obtained from LSOF.
PIPERX should be a regular expression containing a single non-shy match group for matching
the inode numbers of the pipes (the match group should ONLY match the inode number). 
The LSOF arg is interpreted in the same way as `syslog-pid-to-comm'.

When called interactively with no prefix arg a file containing lsof output will be prompted for, 
with a prefix arg a buffer containing lsof output will be prompted for."
  (interactive (list (read-regexp "Regexp containing a non-shy match group"
				  '("pipe:\\[\\([0-9]+\\)\\]"))
		     (if current-prefix-arg
			 (read-buffer "Buffer containing lsof output: " nil t)
		       (read-file-name "File containing lsof output: "))))
  (when (< (regexp-opt-depth piperx) 1)
    (error "PIPERX arg must contain a non-shy match group"))
  (syslog-alter-buffer
   (dolist (pipe (syslog-lsof-get-pipes lsof))
     (let ((rx (replace-regexp-in-string
		"\\\\([^()]+\\\\)"
		(concat "\\(" (car pipe) "\\)") piperx t t))
	   (str (mapconcat (lambda (x)
			     (replace-regexp-in-string "[0-9]+," "" x))
			   (cdr pipe) ":")))
       (goto-char (point-min))
       (while (re-search-forward rx nil t)
	 (replace-match str t t nil 1))))))

;; simple-call-tree-info: CHECK
(cl-defun syslog-transform-strace (lsof &optional (facerx t) faces)
  "Transform strace output in the current buffer.
This is a wrapper for `syslog-replace-pids' & `syslog-replace-pipes':
pids will be replaced with process names, and pipe inode numbers
will be replaced with comma separated lists of file descriptors
and associated processes connected to the pipe."
  (interactive (list (if current-prefix-arg
			 (get-buffer
			  (read-buffer "Buffer containing lsof output: " nil t))
		       (read-file-name "File containing lsof output: "))
		     (let ((choice (completing-read
				    "Highlight type: "
				    '("background" "foreground" "choose"))))
		       (cond ((equal choice "background") "-[^b]\\|[^-].")
			     ((equal choice "foreground") "-b$")
			     ((equal choice "choose")
			      (read-regexp "Regexp matching face names to use (default \".*\"): "
					   ".*"))))
		     (if current-prefix-arg (face-list) syslog-hi-face-defaults)))
  (syslog-replace-pipes "pipe:\\[\\([0-9]+\\)\\]" lsof)
  (highlight-regexp-unique
   (mapconcat 'identity (syslog-replace-pids "^[0-9]+" lsof) "\\|")
   facerx faces))

;; simple-call-tree-info: DONE
(defface syslog-ip
  '((t :underline t :slant italic :weight bold))
  "Face for IPs"
  :group 'syslog)

;; simple-call-tree-info: DONE
(defface syslog-file
  (list (list t :weight 'bold
	      :inherit (if (facep 'diredp-file-name)
			   'diredp-file-name
			 'dired-ignored)))
  "Face for filenames"
  :group 'syslog)

;; simple-call-tree-info: DONE
(defface syslog-hour
  '((t :weight bold  :inherit font-lock-type-face))
  "Face for hours"
  :group 'syslog)

;; simple-call-tree-info: DONE
(defface syslog-error
  '((t  :weight bold :foreground "red"))
  "Face for errors"
  :group 'syslog)

;; simple-call-tree-info: DONE
(defface syslog-warn
  '((t  :weight bold :foreground "goldenrod"))
  "Face for warnings"
  :group 'syslog)

;; simple-call-tree-info: DONE
(defface syslog-info
  '((t  :weight bold :foreground "deep sky blue"))
  "Face for info lines"
  :group 'syslog)

;; simple-call-tree-info: DONE
(defface syslog-debug
  '((t  :weight bold :foreground "medium spring green"))
  "Face for debug lines"
  :group 'syslog)

;; simple-call-tree-info: DONE
(defface syslog-su
  '((t  :weight bold :foreground "firebrick"))
  "Face for su and sudo"
  :group 'syslog)

;; simple-call-tree-info: DONE
(defface syslog-hide
  '((t :foreground "black" :background "black"))
  "Face for hiding text"
  :group 'syslog)

;; Keywords
;; TODO: Seperate the keywords into a list for each format, rather than one for all.
;;       Better matching of dates (even when not at beginning of line).
;; simple-call-tree-info: DONE
(defvar syslog-font-lock-keywords
  '(("\"[^\"]*\"" . 'font-lock-string-face)
    ("'[^']*'" . 'font-lock-string-face)
    ;; Filename at beginning of line
    ("^\\([^ :]+\\): " 1 'syslog-file append)
    ;; Hours: 17:36:00
    ("\\(?:^\\|[[:space:]]\\)\\([[:digit:]]\\{1,2\\}:[[:digit:]]\\{1,2\\}\\(:[[:digit:]]\\{1,2\\}\\)?\\)\\(?:$\\|[[:space:]]\\)" 1 'syslog-hour append)
    ;; Date
    ("\\(?:^\\|[[:space:]]\\)\\([[:digit:]]\\{1,2\\}/[[:digit:]]\\{1,2\\}/[[:digit:]]\\{2,4\\}\\)\\(?:$\\|[[:space:]]\\)" 1 'syslog-hour append)
    ;; Dates: May  9 15:52:34
    ("^\\(?:[^ :]+: \\)?\\(\\(?:[[:alpha:]]\\{3\\}\\)?[[:space:]]*[[:alpha:]]\\{3\\}\\s-+[0-9]+\\s-+[0-9:]+\\)" 1 'font-lock-type-face t)
    ;; Su events
    ("\\(su:.*$\\)" 1 'syslog-su t)
    ("\\(sudo:.*$\\)" 1 'syslog-su t)
    ("\\[[^]]*\\]" . 'font-lock-comment-face)
    ;; IPs
    ("[[:digit:]]\\{1,3\\}\\.[[:digit:]]\\{1,3\\}\\.[[:digit:]]\\{1,3\\}\\.[[:digit:]]\\{1,3\\}" 0 'syslog-ip append)
    ("\\<[Ee][Rr][Rr]\\(?:[Oo][Rr][Ss]?\\)?\\>" 0 'syslog-error append)
    ("\\<[Ii][Nn][Ff][Oo]\\>" 0 'syslog-info append)
    ("\\<[Cc][Rr][Ii][Tt][Ii][Cc][Aa][Ll]\\>" 0 'syslog-error append)
    ("STARTUP" 0 'syslog-info append)
    ("CMD" 0 'syslog-info append)
    ("\\<[Ww][Aa][Rr][Nn]\\(?:[Ii][Nn][Gg]\\)?\\>" 0 'syslog-warn append)
    ("\\<[Dd][Ee][Bb][Uu][Gg]\\>" 0 'syslog-debug append)
    ("(EE)" 0 'syslog-error append)
    ("(WW)" 0 'syslog-warn append)
    ("(II)" 0 'syslog-info append)
    ("(NI)" 0 'syslog-warn append)
    ("(!!)" 0 'syslog-debug append)
    ("(--)" 0 'syslog-debug append)
    ("(\\*\\*)" 0 'syslog-debug append)
    ("(==)" 0 'syslog-debug append)
    ("(\\+\\+)" 0 'syslog-debug append))
  "Expressions to hilight in `syslog-mode'.")

;;; Setup functions
;; simple-call-tree-info: DONE
(defun syslog-find-file-func ()
  "Invoke `syslog-mode' if the buffer appears to be a system logfile.
and another mode is not active.
This function is added to `find-file-hooks'."
  (if (and (eq major-mode 'fundamental-mode)
	   (looking-at syslog-sequence-start-regexp))
      (syslog-mode)))

;; simple-call-tree-info: DONE
(defun syslog-add-hooks ()
  "Add a default set of syslog-hooks.
These hooks will activate `syslog-mode' when visiting a file
which has a syslog-like name (.fasta or .gb) or whose contents
looks like syslog.  It will also turn enable fontification for `syslog-mode'."
  ;; (add-hook 'find-file-hooks 'syslog-find-file-func)
  (add-to-list 'auto-mode-alist
	       '("\\(messages\\(\\.[0-9]\\)?\\|SYSLOG\\)\\'" . syslog-mode)))

;; Setup hooks on request when this mode is loaded.
(if syslog-setup-on-load (syslog-add-hooks))

;; done loading
(run-hooks 'syslog-mode-load-hook)

(provide 'syslog-mode)

;;; syslog-mode.el ends here

;;; (magit-push)
;;; (yaoddmuse-post "EmacsWiki" "syslog-mode.el" (buffer-name) (buffer-string) "update")
