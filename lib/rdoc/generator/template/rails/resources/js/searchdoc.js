Searchdoc = {};

// navigation.js ------------------------------------------

Searchdoc.Navigation = new function() {
    this.initNavigation = function() {
        var _this = this;

        $(document).keydown(function(e) {
            _this.onkeydown(e);
        }).keyup(function(e) {
            _this.onkeyup(e);
        });
    };

    this.navigationActive = function() {
        this.$searchInput ??= document.getElementById("search");
        this.$searchOutput ??= document.getElementById("results");
        return document.activeElement !== this.$searchInput &&
          !this.$searchOutput.contains(document.activeElement);
    };


    this.onkeyup = function(e) {
        if (!this.navigationActive()) return;
        switch (e.keyCode) {
            case 37: //Event.KEY_LEFT:
            case 38: //Event.KEY_UP:
            case 39: //Event.KEY_RIGHT:
            case 40: //Event.KEY_DOWN:
                this.clearMoveTimeout();
                break;
        }
    };

    this.onkeydown = function(e) {
        if (!this.navigationActive()) return;

        switch (e.keyCode) {
            case 37: //Event.KEY_LEFT:
                if (this.moveLeft()) e.preventDefault();
                break;
            case 38: //Event.KEY_UP:
                if (this.moveUp()) e.preventDefault();
                this.startMoveTimeout(false);
                break;
            case 39: //Event.KEY_RIGHT:
                if (this.moveRight()) e.preventDefault();
                break;
            case 40: //Event.KEY_DOWN:
                if (this.moveDown()) e.preventDefault();
                this.startMoveTimeout(true);
                break;
            case 13: //Event.KEY_RETURN:
                if(e.target.dataset["turbo"]) { break; }
                if (this.$current) this.select(this.$current);
                break;
        }
    };

    this.clearMoveTimeout = function() {
        clearTimeout(this.moveTimeout);
        this.moveTimeout = null;
    };

    this.startMoveTimeout = function(isDown) {
        if (this.moveTimeout) this.clearMoveTimeout();
        var _this = this;

        var go = function() {
            if (!_this.moveTimeout) return;
            _this[isDown ? 'moveDown' : 'moveUp']();
            _this.moveTimout = setTimeout(go, 100);
        };
        this.moveTimeout = setTimeout(go, 200);
    };

    this.moveRight = function() {};

    this.moveLeft = function() {};

    this.move = function(isDown) {};

    this.moveUp = function() {
        return this.move(false);
    };

    this.moveDown = function() {
        return this.move(true);
    };
};


// scrollIntoView.js --------------------------------------

function scrollIntoView(element, view) {
    var offset, viewHeight, viewScroll, height;
    offset = element.offsetTop;
    height = element.offsetHeight;
    viewHeight = view.offsetHeight;
    viewScroll = view.scrollTop;
    if (offset - viewScroll + height > viewHeight) {
        view.scrollTop = offset - viewHeight + height;
    }
    if (offset < viewScroll) {
        view.scrollTop = offset;
    }
}

// panel.js -----------------------------------------------

Searchdoc.Panel = function(element, tree) {
    this.$element = $(element);
    this.$current = null;
    this.tree = new Searchdoc.Tree($('.tree', element), tree, this);
};

Searchdoc.Panel.prototype = $.extend({}, Searchdoc.Navigation, new function() {
    this.toggle = function(keys) {
        var keysIndex = 0;
        var _tree = this.tree;
        var _this = this;
        $.each(_tree.$list[0].children, function(i, li) {
            if(keys.length > keysIndex) {
                $li = $(li);
                if($li.text().split(" ")[0] == keys[keysIndex]) {
                    if($li.find('.icon').length > 0) {
                        _tree.toggle($li);
                    }
                    keysIndex += 1;
                    if(keysIndex == keys.length) {
                        _tree.highlight($li)
                    }
                }
            }
        });
    };

    this.open = function(src) {
        var location = $("base").attr("href") + src;
        Turbo.visit(location);
        if (this.highlight) this.highlight(src);
    };
});

// tree.js ------------------------------------------------

Searchdoc.Tree = function(element, tree, panel) {
    this.$element = $(element);
    this.$list = $('ul', element);
    this.tree = tree;
    this.panel = panel;
    this.init();
};

Searchdoc.Tree.prototype = $.extend({}, Searchdoc.Navigation, new function() {
    this.init = function() {
        var stopper = document.createElement('li');
        stopper.className = 'stopper';
        this.$list[0].appendChild(stopper);
        for (var i = 0, l = this.tree.length; i < l; i++) {
            buildAndAppendItem.call(this, this.tree[i], 0, stopper);
        }
        var _this = this;
        this.$list.click(function(e) {
            var $target = $(e.target),
                $li = $target.closest('li');
            if ($target.hasClass('icon')) {
                _this.toggle($li);
            } else {
                _this.select($li);
            }
        });

        this.initNavigation();
    };

    this.select = function($li) {
        this.highlight($li);
        var path = $li[0].searchdoc_tree_data.path;
        if (path) this.panel.open(path);
    };

    this.highlight = function($li) {
        if (this.$current) this.$current.removeClass('current');
        this.$current = $li.addClass('current');
    };

    this.toggle = function($li) {
        var closed = !$li.hasClass('closed'),
            children = $li[0].searchdoc_tree_data.children;
        $li.toggleClass('closed');
        for (var i = 0, l = children.length; i < l; i++) {
            toggleVis.call(this, $(children[i].li), !closed);
        }
    };

    this.moveRight = function() {
        if (!this.$current) {
            this.highlight(this.$list.find('li:first'));
            return;
        }
        if (this.$current.hasClass('closed')) {
            this.toggle(this.$current);
        }
    };

    this.moveLeft = function() {
        if (!this.$current) {
            this.highlight(this.$list.find('li:first'));
            return;
        }
        if (!this.$current.hasClass('closed')) {
            this.toggle(this.$current);
        } else {
            var level = this.$current[0].searchdoc_tree_data.level;
            if (level === 0) return;
            var $next = this.$current.prevAll('li.level_' + (level - 1) + ':visible:first');
            this.$current.removeClass('current');
            $next.addClass('current');
            scrollIntoView($next[0], this.$element[0]);
            this.$current = $next;
        }
    };

    this.move = function(isDown) {
        if (!this.$current) {
            this.highlight(this.$list.find('li:first'));
            return true;
        }
        var next = this.$current[0];
        if (isDown) {
            do {
                next = next.nextSibling;
                if (next && next.style && next.style.display != 'none') break;
            } while (next);
        } else {
            do {
                next = next.previousSibling;
                if (next && next.style && next.style.display != 'none') break;
            } while (next);
        }
        if (next && next.className.indexOf('stopper') == -1) {
            this.$current.removeClass('current');
            $(next).addClass('current');
            scrollIntoView(next, this.$element[0]);
            this.$current = $(next);
        }
        return true;
    };

    function toggleVis($li, show) {
        var closed = $li.hasClass('closed'),
            children = $li[0].searchdoc_tree_data.children;
        $li.css('display', show ? '' : 'none');
        if (!show && this.$current && $li[0] == this.$current[0]) {
            this.$current.removeClass('current');
            this.$current = null;
        }
        for (var i = 0, l = children.length; i < l; i++) {
            toggleVis.call(this, $(children[i].li), show && !closed);
        }
    }

    function buildAndAppendItem(item, level, before) {
        var li = renderItem(item, level),
            list = this.$list[0];
        item.li = li;
        list.insertBefore(li, before);
        for (var i = 0, l = item[3].length; i < l; i++) {
            buildAndAppendItem.call(this, item[3][i], level + 1, before);
        }
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
        cnt.className = 'entry';
        if (!item[1]) li.className = 'empty ';
        cnt.appendChild(h1);
        // cnt.appendChild(p);
        h1.appendChild(document.createTextNode(item[0]));
        // p.appendChild(document.createTextNode(item[4]));
        if (item[2]) {
            i = document.createElement('i');
            i.appendChild(document.createTextNode(item[2]));
            h1.appendChild(i);
        }
        if (item[3].length > 0) {
            icon = document.createElement('div');
            icon.className = 'icon';
            cnt.appendChild(icon);
        }

        // user direct assignement instead of $()
        // it's 8x faster
        // $(li).data('path', item[1])
        //     .data('children', item[3])
        //     .data('level', level)
        //     .css('display', level == 0 ? '' : 'none')
        //     .addClass('level_' + level)
        //     .addClass('closed');
        li.searchdoc_tree_data = {
            path: item[1],
            children: item[3],
            level: level
        };
        li.style.display = level === 0 ? '' : 'none';
        li.className += 'level_' + level + ' closed';
        return li;
    }

    function getOffset(level) {
        return 5 + 18 * level + 'px';
    }
});
