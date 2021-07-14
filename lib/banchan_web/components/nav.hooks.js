// Install js-cookie again and uncomment the appropriate lines below to make
// the navbar-burger open/close state "sticky"
// import Cookie from 'js-cookie';

const Nav = {
    handle_burger() {
        // Get all "navbar-burger" elements
        const $navbarBurgers = [...document.querySelectorAll('.navbar-burger')];

        // Check if there are any navbar burgers
        if ($navbarBurgers.length > 0) {

            //
            // const isOpen = Cookie.get("navbar-burger-open") === "true";

            // Add a click event on each of them
            $navbarBurgers.forEach(el => {
                // el.classList.toggle('is-active', isOpen);
                // el.parentNode.parentNode.querySelector(".navbar-menu").classList.toggle('is-active', isOpen);
                el.addEventListener('click', () => {

                    // Get the target from the "data-target" attribute
                    const target = el.dataset.target;
                    const $target = document.getElementById(target);

                    // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
                    el.classList.toggle('is-active');
                    $target.classList.toggle('is-active');
                    // Cookie.set("navbar-burger-open", isOpen === "true" ? "false" : "true");
                });
            });
        }
    },
    handle_active() {
        for (const link of [...document.querySelectorAll('.navbar-item')]) {
            link.classList.toggle('is-active', link.href === window.location.href);
        }
    },
    mounted() {
        this.handle_burger();
        this.handle_active();
    }
};

export { Nav };
