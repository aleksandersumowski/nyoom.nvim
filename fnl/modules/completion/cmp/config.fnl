(import-macros {: set! : nyoom-module-p! : packadd!} :macros)
(local {: autoload} (require :core.lib.autoload))
(local {: setup} (require :core.lib.setup))
(local cmp (autoload :cmp))
(local luasnip (autoload :luasnip))

;; vim settings

(set! completeopt [:menu :menuone :noselect])

;; add general cmp sources

(local cmp-sources [])

(table.insert cmp-sources {:name :luasnip :group_index 1})
(table.insert cmp-sources {:name :buffer :group_index 2})
(table.insert cmp-sources {:name :path :group_index 2})
(table.insert cmp-sources {:name :path :group_index 2})

;; add conditional sources

(nyoom-module-p! lsp
                 (table.insert cmp-sources {:name :nvim_lsp :group_index 1}))

(nyoom-module-p! rust (table.insert cmp-sources {:name :crates :group_index 1}))
(nyoom-module-p! neorg (table.insert cmp-sources {:name :neorg :group_index 1}))
(nyoom-module-p! eval
                 (table.insert cmp-sources {:name :conjure :group_index 1}))
;; copilot

(nyoom-module-p! copilot
                 (do
                   (packadd! copilot-cmp)
                   (setup :copilot_cmp)
                   (table.insert cmp-sources {:name :copilot :group_index 2})))

;; copilot uses lines above/below current text which confuses cmp, fix:

(fn has-words-before []
  (when (= (vim.api.nvim_buf_get_option 0 :buftype) :prompt)
    (lua "return false"))
  (local (line col) (unpack (vim.api.nvim_win_get_cursor 0)))
  (and (not= col 0) (= (: (. (vim.api.nvim_buf_get_text 0 (- line 1) 0
                                                        (- line 1) col {})
                             1) :match "^%s*$") nil)))

(fn border [hl-name]
  :solid)

(local cmp-window (require :cmp.utils.window))

;; default icons (lspkind)

(local icons {:Text ""
              :Method ""
              :Function ""
              :Constructor "⌘"
              :Field "ﰠ"
              :Variable ""
              :Class "ﴯ"
              :Interface ""
              :Module ""
              :Unit "塞"
              :Property "ﰠ"
              :Value ""
              :Enum ""
              :Keyword "廓"
              :Snippet ""
              :Color ""
              :File ""
              :Reference ""
              :Folder ""
              :EnumMember ""
              :Constant ""
              :Struct "פּ"
              :Event ""
              :Operator ""
              :Copilot ""
              :TypeParameter ""})

(setup :cmp {:experimental {:ghost_text true}
             :window {:documentation {:border (border :CmpDocBorder)
                                      :max_height 30}
                      :completion {:border (border :CmpBorder)
                                   :max_height 30
                                   :scrolloff 5}}
             :view {:entries {:name :custom :selection_order :near_cursor}}
             :preselect cmp.PreselectMode.None
             :snippet {:expand (fn [args]
                                 (luasnip.lsp_expand args.body))}
             :mapping {:<C-b> (cmp.mapping.scroll_docs -4)
                       :<C-f> (cmp.mapping.scroll_docs 4)
                       :<C-space> (cmp.mapping.complete)
                       :<C-c> (fn [fallback]
                                (if (cmp.visible)
                                    (do
                                      (cmp.mapping.close)
                                      (vim.cmd :stopinsert))
                                    (fallback)))
                       :<up> (cmp.mapping.select_next_item)
                       :<down> (cmp.mapping.select_prev_item)
                       :<Tab> (vim.schedule_wrap (fn [fallback]
                                                   (if (and (cmp.visible)
                                                            (has-words-before))
                                                       (cmp.select_next_item {:behavior cmp.SelectBehavior.Select})
                                                       (luasnip.expand_or_jumpable)
                                                       (luasnip.expand_or_jump)
                                                       (fallback)
                                                       [:i :s :c])))
                       :<S-Tab> (vim.schedule_wrap (fn [fallback]
                                                     (if (and (cmp.visible)
                                                              (has-words-before))
                                                         (cmp.select_prev_item {:behavior cmp.SelectBehavior.Select})
                                                         (luasnip.jumpable -1)
                                                         (luasnip.jump -1)
                                                         (fallback)))
                                                   [:i :s :c])
                       :<CR> (cmp.mapping.confirm {:behavior cmp.ConfirmBehavior.Replace
                                                   :select false})
                       :<space> (cmp.mapping.confirm {:select false})}
             : cmp-sources
             :formatting {:fields {1 :kind 2 :abbr 3 :menu}
                          :format (fn [_ vim-item]
                                    (set vim-item.menu vim-item.kind)
                                    (set vim-item.kind (. icons vim-item.kind))
                                    vim-item)}})

;; Enable command-line completions

(cmp.setup.cmdline "/"
                   {:mapping (cmp.mapping.preset.cmdline)
                    :sources [{:name :buffer :group_index 1}]})

;; Enable search completions

(cmp.setup.cmdline ":"
                   {:mapping (cmp.mapping.preset.cmdline)
                    :sources [{:name :path} {:name :cmdline :group_index 1}]})

;; snippets

((. (require :luasnip.loaders.from_vscode) :lazy_load))
((. (require :luasnip.loaders.from_lua) :lazy_load))

(nyoom-module-p! copilot (cmp.event:on :menu_opened
                                       (fn []
                                         (set vim.b.copilot_suggestion_hidden
                                              true)))
                 (cmp.event:on :menu_closed
                               (fn []
                                 (set vim.b.copilot_suggestion_hidden false))))
