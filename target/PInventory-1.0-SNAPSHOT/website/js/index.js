/**
 * Modal & Page Management System
 */

// Modal Utility Functions
export function openModal(id) {
    const modal = document.getElementById(id);
    if (modal) {
        modal.classList.add('active');
        // Fallback inline style support if your CSS uses display toggling
        modal.style.display = 'flex';
    }
}

export function closeModal(id) {
    const modal = document.getElementById(id);
    if (modal) {
        modal.classList.remove('active');
        // Fallback inline style support
        modal.style.display = 'none';
    }
}

// Expose modal methods globally to support inline onclick handlers in JSP
window.openModal = openModal;
window.closeModal = closeModal;

// Helper function to safely set input values if elements exist
function setInputValue(id, value = '') {
    const input = document.getElementById(id);
    if (input) {
        input.value = value;
    }
}

document.addEventListener('DOMContentLoaded', () => {

    // 1. Close Modal on Backdrop Click
    window.addEventListener('click', (e) => {
        if (e.target && e.target.classList.contains('modal-backdrop')) {
            const modalId = e.target.getAttribute('id');
            if (modalId) {
                closeModal(modalId);
            } else {
                e.target.classList.remove('active');
                e.target.style.display = 'none';
            }
        }
    });

    // 2. Edit Page Click Handlers
    document.querySelectorAll('.btn-edit-page').forEach((btn) => {
        btn.addEventListener('click', function () {
            const id = this.getAttribute('data-id') || '';
            const title = this.getAttribute('data-title') || '';
            const slug = this.getAttribute('data-slug') || '';
            const parentId = this.getAttribute('data-parent-id') || '';

            setInputValue('editPageId', id);
            setInputValue('editPageTitle', title);
            setInputValue('editPageSlug', slug);
            setInputValue('editParentId', parentId);

            openModal('editPageModal');
        });
    });

    // 3. Edit Section Click Handlers
    document.querySelectorAll('.btn-edit-section').forEach((btn) => {
        btn.addEventListener('click', function () {
            const secId = this.getAttribute('data-id') || '';
            const type = this.getAttribute('data-type') || '';
            const seq = this.getAttribute('data-seq') || '1';
            const title = this.getAttribute('data-title') || '';

            setInputValue('editSectionId', secId);
            setInputValue('editSectionType', type);
            setInputValue('editSectionSeq', seq);
            setInputValue('editSectionTitle', title);

            const contentStore = document.getElementById(`section-content-data-${secId}`);
            setInputValue('editSectionContent', contentStore ? contentStore.innerText.trim() : '');

            openModal('editSectionModal');
        });
    });

    // 4. Edit Image / Sequenced Asset Click Handlers
    document.querySelectorAll('.btn-edit-image').forEach((btn) => {
        btn.addEventListener('click', function () {
            const id = this.getAttribute('data-id') || '';
            const seq = this.getAttribute('data-seq') || '1';
            const alt = this.getAttribute('data-alt') || '';
            const h1 = this.getAttribute('data-h1') || '';
            const h2 = this.getAttribute('data-h2') || '';

            setInputValue('editImageId', id);
            setInputValue('editImageSeq', seq);
            setInputValue('editImageAlt', alt);
            setInputValue('editImageH1', h1);
            setInputValue('editImageH2', h2);

            openModal('editImageModal');
        });
    });

    // 5. Sticky Navigation Scrollspy Highlights
    const navLinks = document.querySelectorAll('.page-nav-sidebar .nav-link');
    const targets = document.querySelectorAll('#page-overview, .section-card');

    if (navLinks.length > 0 && targets.length > 0) {
        const observerOptions = {
            root: null,
            rootMargin: '-10% 0px -70% 0px',
            threshold: 0,
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting) {
                    const id = entry.target.getAttribute('id');
                    if (!id) return;

                    navLinks.forEach((link) => {
                        link.classList.toggle('active', link.getAttribute('href') === `#${id}`);
                    });
                }
            });
        }, observerOptions);

        targets.forEach((target) => observer.observe(target));
    }
});