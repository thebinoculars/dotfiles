(( $+commands[rga] )) || return

rga-fzf() {
	local RG_PREFIX="rga --files-with-matches"
	local file
	file="$(
		FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
			fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
				--phony -q "$1" \
				--bind "change:reload:$RG_PREFIX {q}" \
				--preview-window="70%:wrap"
	)" &&
	echo "opening $file" &&
	if command -v wslview >/dev/null 2>&1; then
		wslview "$file"
	else
		xdg-open "$file"
	fi
}
