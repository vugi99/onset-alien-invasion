// Inventory component
Vue.component('inventory', {
    template: '#inventory',
    data() {
        return {
            items: []
        }
    },
    mounted() {
        EventBus.$on('SetInventory', (data) => {
            this.items = data
        })
    }
})

// Hud component
new Vue({
    el: '#hud',
    data() {
        return {
            show_blood: false,
            message: null,
            banner: null
        }
    },
    methods: {
        ShowBlood: function () {
            this.show_blood = true;

            var that = this;
            setTimeout(function () {
                that.show_blood = false;
            }, 3500);
        },
        ShowMessage: function (message) {
            this.message = message;

            var that = this;
            setTimeout(function () {
                that.message = null;
            }, 5000);
        },
        ShowBanner: function (banner) {
            this.banner = banner;

            var that = this;
            setTimeout(function () {
                that.banner = null;
            }, 5000);
        }

    },
    mounted() {
        EventBus.$on('ShowBlood', this.ShowBlood);
        EventBus.$on('ShowMessage', this.ShowMessage)
        EventBus.$on('ShowBanner', this.ShowBanner)
    }
});


// dev seeding
(function () {
    if (typeof indev !== 'undefined') {
        EmitEvent('SetInventory', [
            {
                "name": "scrap",
                "modelid": 694,
                "quantity": 2
            }
        ]);

        EmitEvent('ShowBlood');
        EmitEvent('ShowMessage', 'You have found an important piece! Take this to the satellite!');
        EmitEvent('ShowBanner', 'Welcome to the invasion!');

    }
})();
