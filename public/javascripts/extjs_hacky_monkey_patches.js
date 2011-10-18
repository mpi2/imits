Ext.onReady(function() {
    function patches_for_4_0_2() {
        Ext.override(Ext.menu.Menu, {
            doConstrain: function() {
                var me = this,
                y = me.el.getY(),
                max, full,
                vector,
                returnY = y, normalY, parentEl, scrollTop, viewHeight;

                full = me.getHeight();
                delete me.height;
                me.setSize();
                if (me.floating) {
                    parentEl = Ext.fly(me.el.dom.parentNode);
                    scrollTop = parentEl.getScroll().top;
                    viewHeight = parentEl.getViewSize().height;
                    //Normalize y by the scroll position for the parent element.  Need to move it into the coordinate space
                    //of the view.
                    normalY = y - scrollTop;
                    max = me.maxHeight ? me.maxHeight : viewHeight - normalY;
                    if (full > viewHeight) {
                        max = viewHeight;
                        //Set returnY equal to (0,0) in view space by reducing y by the value of normalY
                        returnY = y - normalY;
                    } else if (max < full) {
                        returnY = y - (full - max);
                        max = full;
                    }
                }else{
                    max = me.getHeight();
                }
                // Always respect maxHeight
                if (me.maxHeight){
                    max = Math.min(me.maxHeight, max);
                }
                if (full > max && max > 0){
                    me.layout.autoSize = false;
                    me.setHeight(max);
                    if (me.showSeparator){
                        me.iconSepEl.setHeight(me.layout.getRenderTarget().dom.scrollHeight);
                    }
                }
                vector = me.getConstrainVector(me.el.dom.parentNode);
                if (vector) {
                    me.setPosition(me.getPosition()[0] + vector[0]);
                }
                me.el.setY(returnY);

            }
        });

        Ext.override(Ext.data.Store, {
            afterEdit : function(record) {
                var me = this;

                if (me.autoSync) {
                    me.sync();
                }

                if (record.dirty) {
                    record.commit();
                }
                me.fireEvent('update', me, record, Ext.data.Model.EDIT);
            },

            afterReject : function(record) {
                if (record.dirty) {
                    record.commit();
                }
                this.fireEvent('update', this, record, Ext.data.Model.REJECT);
            },

            afterCommit : function(record) {
                if (record.dirty) {
                    record.commit();
                }
                this.fireEvent('update', this, record, Ext.data.Model.COMMIT);
            }

        });
    }

    function patches_for_4_0_6() {
        Ext.override(Ext.EventObjectImpl, {
            correctWheelDelta: function (delta) {
                var scale = this.WHEEL_SCALE,
                ret=Math.round(delta/scale);

                if (!ret && delta) {
                    ret = (delta < 0) ? -1 : 1;
                }
                return ret;
            }
        });
    }

    var extvers = [Ext.versions.core.major, Ext.versions.core.minor, Ext.versions.core.patch];

    if(extvers[0] != 4 || extvers[1] != 0) {
        return;
    }

    if(extvers[2] <= 6) {
        patches_for_4_0_6();
    }

    if(extvers[2] <= 2) {
        patches_for_4_0_2();
    }
});
