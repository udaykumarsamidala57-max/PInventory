const autoPlayTimers = {};

function showSlide(container, index) {
    const slides = container.querySelectorAll('.hero-slide');
    const dots = container.querySelectorAll('.dot');
    
    if (slides.length === 0) return;

    slides.forEach((slide, i) => {
        slide.classList.toggle('active', i === index);
    });

    dots.forEach((dot, i) => {
        dot.classList.toggle('active', i === index);
    });
}

function nextSlide(containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;
    
    const slides = container.querySelectorAll('.hero-slide');
    let currentIndex = -1;

    slides.forEach((slide, index) => {
        if (slide.classList.contains('active')) {
            currentIndex = index;
        }
    });

    let newIndex = (currentIndex + 1) % slides.length;
    showSlide(container, newIndex);
}

function manualChangeSlide(containerId, step) {
    const container = document.getElementById(containerId);
    if (!container) return;
    
    const slides = container.querySelectorAll('.hero-slide');
    let currentIndex = -1;

    slides.forEach((slide, index) => {
        if (slide.classList.contains('active')) {
            currentIndex = index;
        }
    });

    let newIndex = currentIndex + step;
    if (newIndex >= slides.length) newIndex = 0;
    if (newIndex < 0) newIndex = slides.length - 1;

    showSlide(container, newIndex);
    resetAutoplay(containerId);
}

function manualGoToSlide(containerId, index) {
    const container = document.getElementById(containerId);
    if (!container) return;
    
    showSlide(container, index);
    resetAutoplay(containerId);
}

function startAutoplay(containerId, interval) {
    autoPlayTimers[containerId] = setInterval(() => {
        nextSlide(containerId);
    }, interval);
}

function resetAutoplay(containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;
    
    const interval = parseInt(container.getAttribute('data-interval'), 10) || 4000;
    
    if (autoPlayTimers[containerId]) {
        clearInterval(autoPlayTimers[containerId]);
    }
    startAutoplay(containerId, interval);
}

function closePopupModal(modalId) {
    const modalElement = document.getElementById(modalId);
    if (modalElement) {
        modalElement.style.display = 'none';
    }
}

// Auto-initialize slideshow containers when DOM is loaded
document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll('.hero-fullscreen-container[data-autoplay="true"]').forEach(container => {
        const interval = parseInt(container.getAttribute('data-interval'), 10) || 4000;
        startAutoplay(container.id, interval);
    });
});