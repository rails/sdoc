Searchdoc = {};
(function() {
    Searchdoc.Searcher = function(data) {
        this.data = data;
        this.handlers = [];
    }

    Searchdoc.Searcher.prototype = new function() {
        var CHUNK_SIZE = 1000, // search is performed in chunks of 1000 for non-bloking user input
            MAX_RESULTS = 100, // do not search more than 100 results
            huid = 0, suid = 0,
            runs = 0;
    
    
        this.find = function(query) {
            var queries = splitQuery(query),
                regexps = buildRegexps(queries),
                highlighters = buildHilighters(queries),
                state = { from: 0, pass: 0, limit: MAX_RESULTS, n: suid++},
                _this = this;
            if (this.lastQuery == query) return;
            this.lastQuery = query;
        
            if (!query) return;
        
            // console.log(runs);
            var run = function() {
                if (query != _this.lastQuery) return;
                triggerResults.call(_this, performSearch(regexps, queries, highlighters, state));
                if (state.limit > 0 && state.pass < 3) {
                    setTimeout(run, 2);
                }
                runs++;
            };
            runs = 0;
            run();
        }
    
        this.ready = function(fn) {
            fn.huid = huid;
            this.handlers.push(fn);
        }
    
        function splitQuery(query) {
            return jQuery.grep(query.split(/\s+/), function(string) { return !!string });
        }
    
        function buildRegexps(queries) {
            return jQuery.map(queries, function(query) { return new RegExp(query.replace(/(.)/g, '([$1])([^$1]*?)'), 'i') });
        }
    
        function buildHilighters(queries) {
            return jQuery.map(queries, function(query) {
                return jQuery.map( query.split(''), function(l, i){ return '\u0001$' + (i*2+1) + '\u0002$' + (i*2+2) } ).join('')
            });
        }
    
        function longMatchRegexp(index, longIndex, regexps) {
            for (var i = regexps.length - 1; i >= 0; i--){
                if (!index.match(regexps[i]) && !longIndex.match(regexps[i])) return false;
            };
            return true;
        }
        
        function matchPass1(index, longIndex, queries, regexps) {
            if (index.indexOf(queries[0]) != 0) return false;
            for (var i=1, l = regexps.length; i < l; i++) {
                if (!index.match(regexps[i]) && !longIndex.match(regexps[i])) return false;
            };
            return true;
        }
    
        function matchPass2(index, longIndex, queries, regexps) {
            if (index.indexOf(queries[0]) == -1) return false;
            for (var i=1, l = regexps.length; i < l; i++) {
                if (!index.match(regexps[i]) && !longIndex.match(regexps[i])) return false;
            };
            return true;
        }
        
        function matchPassRegexp(index, longIndex, regexps) {
            for (var i=0, l = regexps.length; i < l; i++) {
                if (!index.match(regexps[i]) && (i == 0 || !longIndex.indexOf(regexps[i]))) return false;
            };
            return true;
        }
    
        function highlightRegexp(info, regexps, highlighters) {
            var result = createResult(info);
            for (var i=0, l = regexps.length; i < l; i++) {
                result.title = result.title.replace(regexps[i], highlighters[i]);
                if (i > 0)
                    result.namespace = result.namespace.replace(regexps[i], highlighters[i]);
            };
            return result;
        }
        
        function hltSubstring(string, pos, length) {
            return string.substring(0, pos) + '\u0001' + string.substring(pos, pos + length) + '\u0002' + string.substring(pos + length);
        }
        
        function highlightQuery(info, queries, regexps, highlighters) {
            var result = createResult(info), pos = 0, lcTitle = result.title.toLowerCase();
            pos = lcTitle.indexOf(queries[0]);
            if (pos != -1) {
                result.title = hltSubstring(result.title, pos, queries[0].length);
            }
            for (var i=1, l = regexps.length; i < l; i++) {
                result.title = result.title.replace(regexps[i], highlighters[i]);
                result.namespace = result.namespace.replace(regexps[i], highlighters[i]);
            };
            return result;
        }
    
        function createResult(info) {
            var result = {};
            result.title = info[0];
            result.namespace = info[1];
            result.path = info[2];
            result.params = info[3];
            result.snippet = info[4];
            return result;
        }
    
        function triggerResults(results) {
            jQuery.each(this.handlers, function(i, fn) { fn.call(this, results) })
        }
    
        function performSearch(regexps, queries, highlighters, state) {
            var searchIndex = data.searchIndex, // search only by title first and then by source
                longSearchIndex = data.longSearchIndex,
                info = data.info,
                result = [],
                i = state.from, 
                l = searchIndex.length,
                togo = CHUNK_SIZE;
            if (state.pass == 0) {
                for (; togo > 0 && i < l && state.limit > 0; i++, togo--) {
                    if (matchPass1(searchIndex[i], longSearchIndex[i], queries, regexps)) {
                        info[i].n = state.n;
                        result.push(highlightQuery(info[i], queries, regexps, highlighters));
                        state.limit--;
                    }
                };
            }
            if (searchIndex.length <= i) {
                state.pass++;
                i = state.from = 0;
            }
            if (state.pass == 1) {
                for (; togo > 0 && i < l && state.limit > 0; i++, togo--) {
                    if (info[i].n == state.n) continue;
                    if (matchPass2(searchIndex[i], longSearchIndex[i], queries, regexps)) {
                        info[i].n = state.n;
                        result.push(highlightQuery(info[i], queries, regexps, highlighters));
                        state.limit--;
                    }
                };
            }
            if (searchIndex.length <= i) {
                state.pass++;
                i = state.from = 0;
            }
            if (state.pass == 2) {
                for (; togo > 0 && i < l && state.limit > 0; i++, togo--) {
                    if (info[i].n == state.n) continue;
                    if (matchPassRegexp(searchIndex[i], longSearchIndex[i], regexps)) {
                        result.push(highlightRegexp(info[i], regexps, highlighters));
                        state.limit--;
                    }
                };
            }
            if (searchIndex.length <= i) {
                state.pass++;
                state.from = 0;
            } else {
                state.from = i;
            }
            return result;
        }
    }



    Searchdoc.Tree = function(element, tree, panel) {
        this.$element = $(element);
        this.$list = $('ul', element);
        this.tree = tree;
        this.panel = panel;
        this.init();
    }

    Searchdoc.Tree.prototype = new function() {
        this.init = function() {
            var stopper = document.createElement('li');
            stopper.className = 'stopper';
            this.$list[0].appendChild(stopper);
            for (var i=0, l = this.tree.length; i < l; i++) {
                buildAndAppendItem.call(this, this.tree[i], 0, stopper);
            };
            var _this = this;
            this.$list.click(function(e) {
                var $target = $(e.target),
                    $li = $target.closest('li');
                if ($target.hasClass('icon')) {
                    _this.toggle($li);
                } else {
                    _this.select($li);
                }
            })

            $(document).keydown(function(e) {
                _this.onkeydown(e);
            }).keyup(function(e) {
                _this.onkeyup(e);
            })
        
        }
    
        this.select = function($li) {
            var path = $li.data('path');
            if (this.$current) this.$current.removeClass('current');
            this.$current = $li.addClass('current');
            if (path) this.panel.open(path);
        }
    
        this.toggle = function($li) {
            var closed = !$li.hasClass('closed'),
                children = $li.data('children');
            $li.toggleClass('closed');
            for (var i=0, l = children.length; i < l; i++) {
                toggleVis.call(this, $(children[i].li), !closed);
            };
        }
    
        this.onkeyup = function(e) {
            if (!this.active) return;
            switch(e.keyCode) {
                case 37: //Event.KEY_LEFT:
                case 38: //Event.KEY_UP:
                case 39: //Event.KEY_RIGHT:
                case 40: //Event.KEY_DOWN:
                    this.clearMoveTimeout();
                    break;
                }
        }
    
        this.onkeydown = function(e) {
            if (!this.active) return;
            switch(e.keyCode) {
                case 37: //Event.KEY_LEFT:
                    this.moveLeft();
                    e.preventDefault();
                    break;
                case 38: //Event.KEY_UP:
                    this.moveUp();
                    e.preventDefault();
                    this.startMoveTimeout(false);
                    break;
                case 39: //Event.KEY_RIGHT:
                    this.moveRight();
                    e.preventDefault();
                    break;
                case 40: //Event.KEY_DOWN:
                    this.moveDown();
                    e.preventDefault();
                    this.startMoveTimeout(true);
                    break;
                case 9: //Event.KEY_TAB:
                case 13: //Event.KEY_RETURN:
                    if (this.$current) this.select(this.$current);
                    break;
            }
        }
    
        this.clearMoveTimeout = function() {
            clearTimeout(this.moveTimeout); 
            this.moveTimeout = null;
        }
    
        this.startMoveTimeout = function(isDown) {
            if (this.moveTimeout) this.clearMoveTimeout();
            var _this = this;
        
            var go = function() {
                if (!_this.moveTimeout) return;
                _this[isDown ? 'moveDown' : 'moveUp']();
                _this.moveTimout = setTimeout(go, 100);
            }
            this.moveTimeout = setTimeout(go, 200);
        }    
        
        this.moveRight = function() {
            if (!this.$current) {
                this.select(this.$list.find('li:first'));
                return;
            }
            if (this.$current.hasClass('closed')) {
                this.toggle(this.$current);
            }
        }
        
        this.moveLeft = function() {
            if (!this.$current) {
                this.select(this.$list.find('li:first'));
                return;
            }
            if (!this.$current.hasClass('closed')) {
                this.toggle(this.$current);
            } else {
                var level = this.$current.data('level');
                if (level == 0) return;
                var $next = this.$current.prevAll('li.level_' + (level - 1) + ':visible:first');
                this.$current.removeClass('current');
                $next.addClass('current');
                scrollIntoView($next, this.$element);
                this.$current = $next;
            }
        }
    
        this.move = function(isDown) {
            if (!this.$current) {
                this.select(this.$list.find('li:first'));
                return;
            }
            var $next = this.$current[isDown ? 'nextAll' : 'prevAll']('li:visible:eq(0)');
            if ($next.length) {
                this.$current.removeClass('current');
                $next.addClass('current');
                scrollIntoView($next, this.$element);
                this.$current = $next;
            }
        }
    
        this.moveUp = function() {
            this.move(false);
        }
    
        this.moveDown = function() {
            this.move(true);
        }
    
        function toggleVis($li, show) {
            var closed = $li.hasClass('closed'),
                children = $li.data('children');
            $li.css('display', show ? '' : 'none')
            if (!show && this.$current && $li[0] == this.$current[0]) {
                this.$current.removeClass('current');
                this.$current = null;
            }
            for (var i=0, l = children.length; i < l; i++) {
                toggleVis.call(this, $(children[i].li), show && !closed);
            };
        }
    
        function buildAndAppendItem(item, level, before) {
            var li   = renderItem(item, level),
                list = this.$list[0];
            item.li = li;
            list.insertBefore(li, before);
            for (var i=0, l = item[3].length; i < l; i++) {
                buildAndAppendItem.call(this, item[3][i], level + 1, before);
            };
            return li;
        }
    
        function renderItem(item, level) {
            var li = document.createElement('li'),
                cnt = document.createElement('div'),
                h1 = document.createElement('h1'),
                p = document.createElement('p'),
                icon, i;
            
            li.appendChild(cnt);
            li.style.paddingLeft = getOffset(level);
            cnt.className = 'content';
            if (!item[1]) li.className  = 'empty';
            cnt.appendChild(h1);
            // cnt.appendChild(p);
            h1.appendChild(document.createTextNode(item[0]));
            // p.appendChild(document.createTextNode(item[4]));
            if (item[2]) {
                i = document.createElement('i');
                i.appendChild(document.createTextNode(item[3]));
                h1.appendChild(i);
            }
            if (item[3].length > 0) {
                icon = document.createElement('div');
                icon.className = 'icon';
                cnt.appendChild(icon);
            }
            
            $(li).data('path', item[1])
                .data('children', item[3])
                .data('level', level)
                .css('display', level == 0 ? '' : 'none')
                .addClass('level_' + level)
                .addClass('closed');
            return li;
        }
    
        function getOffset(level) {
            return 5 + 18*level + 'px';
        }
    }



    Searchdoc.Panel = function(element, data, tree, frame) {
        this.$element = $(element);
        this.$input = $('input', element).eq(0);
        this.$result = $('.result ul', element).eq(0);
        this.frame = frame;
        this.$current = null;
        this.$view = this.$result.parent();
        this.searcher = new Searchdoc.Searcher(data);
        this.tree = new Searchdoc.Tree($('.tree', element), tree, this);
        this.tree.active = true;
        this.init();
    }

    Searchdoc.Panel.prototype = new function() {
        var suid = 1;
    
        this.init = function() {
            var _this = this;
            this.$input.keyup(function() {
                _this.search(this.value);
            });
        
            this.$input.keydown(function(e) {
                _this.onkeydown(e);
            })
        
            this.$input.keyup(function(e) {
                _this.onkeyup(e);
            })
        
            this.searcher.ready(function(results) {
                _this.addResults(results);
            })
        
            this.$result.click(function(e) {
                _this.$current.removeClass('current');
                _this.$current = $(e.target).closest('li').addClass('current');
                _this.select();
                _this.$input.focus();
            });
        }
    
        this.search = function(value) {
            value = jQuery.trim(value).toLowerCase();
            if (value) {
                this.$element.removeClass('panel_tree').addClass('panel_results');
                this.tree.active = false;
            } else {
                this.$element.addClass('panel_tree').removeClass('panel_results');
                this.tree.active = true;
            }
            if (value != this.searcher.lastQuery) {
                this.$result.empty();
                this.$current = null;
            }
            this.firstRun = true;
            this.searcher.find(value);
        }
    
        this.addResults = function(results) {
            var target = this.$result.get(0);
            for (var i=0, l = results.length; i < l; i++) {
                target.appendChild(renderItem(results[i]));
            };
            if (this.firstRun && results.length > 0) {
                this.firstRun = false;
                this.$current = $(target.firstChild);
                this.$current.addClass('current');
                scrollIntoView(this.$current, this.$view)
            }
            if (jQuery.browser.msie) this.$element[0].className += '';
        }
    
        this.onkeyup = function(e) {
            if (this.tree.active) return;
            switch(e.keyCode) {
                case 38: //Event.KEY_UP:
                    this.clearMoveTimeout();
                    break;
                case 40: //Event.KEY_DOWN:
                    this.clearMoveTimeout();
                    break;
                }
        }
    
        this.onkeydown = function(e) {
            if (this.tree.active) return;
            switch(e.keyCode) {
                case 38: //Event.KEY_UP:
                    this.moveUp();
                    e.preventDefault();
                    this.startMoveTimeout(false);
                    break;
                case 40: //Event.KEY_DOWN:
                    this.moveDown();
                    e.preventDefault();
                    this.startMoveTimeout(true);
                    break;
                case 9: //Event.KEY_TAB:
                case 13: //Event.KEY_RETURN:
                    this.select();
                    break;
            }
        }
    
        this.clearMoveTimeout = function() {
            clearTimeout(this.moveTimeout); 
            this.moveTimeout = null;
        }
    
        this.startMoveTimeout = function(isDown) {
            if (this.moveTimeout) this.clearMoveTimeout();
            var _this = this;
        
            var go = function() {
                if (!_this.moveTimeout) return;
                _this[isDown ? 'moveDown' : 'moveUp']();
                _this.moveTimout = setTimeout(go, 100);
            }
            this.moveTimeout = setTimeout(go, 200);
        }
    
        this.open = function(src) {
            this.frame.location = '../' + src;
        }
    
        this.select = function() {
            this.open(this.$current.data('path'));
        }
    
        this.move = function(isDown) {
            if (!this.$current) return;
            var $next = this.$current[isDown ? 'next' : 'prev']();
            if ($next.length) {
                this.$current.removeClass('current');
                $next.addClass('current');
                scrollIntoView($next, this.$view);
                this.$current = $next;
            }
        }
    
        this.moveUp = function() {
            this.move(false);
        }
    
        this.moveDown = function() {
            this.move(true);
        }
    
        function renderItem(result) {
            var li = document.createElement('li'),
                html = '';
            html += '<h1>' + hlt(result.title);
            if (result.params) html += '<i>' + result.params + '</i></h1>';
            html += '<p>' + hlt(result.namespace) + '</p>';
            if (result.snippet) html += '<p class="snippet">' + escapeHTML(result.snippet) + '</p>';
            li.innerHTML = html;
            jQuery.data(li, 'path', result.path);
            return li;
        }
    
        function hlt(html) {
            return escapeHTML(html).replace(/\u0001/g, '<b>').replace(/\u0002/g, '</b>')
        }
    
        function escapeHTML(html) {
            return html.replace(/[&<>]/g, function(c) {
                return '&#' + c.charCodeAt(0) + ';';
            });
        }
    
    }

    function scrollIntoView($element, $view) {
        var offset, viewHeight, viewScroll, height;
        offset = $element[0].offsetTop;
        height = $element[0].offsetHeight;
        viewHeight = $view[0].offsetHeight;
        viewScroll = $view[0].scrollTop;
        if (offset - viewScroll + height > viewHeight) {
            $view[0].scrollTop = offset - viewHeight + height;
        }
        if (offset < viewScroll) {
            $view[0].scrollTop = offset;
        }
    }
})()