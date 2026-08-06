(() => {
  const root = document.querySelector('[data-vf-carousel]');
  if (!root) return;

  const slides = Array.from(root.querySelectorAll('.vf-carousel__slide'));
  const dots = Array.from(root.querySelectorAll('.vf-carousel__dot'));
  const prev = root.querySelector('.vf-carousel__prev');
  const next = root.querySelector('.vf-carousel__next');
  const caption = root.querySelector('.vf-carousel__caption');
  let index = slides.findIndex((s) => s.classList.contains('is-active'));
  if (index < 0) index = 0;

  const show = (i) => {
    index = (i + slides.length) % slides.length;
    slides.forEach((slide, n) => {
      slide.classList.toggle('is-active', n === index);
      slide.setAttribute('aria-hidden', n === index ? 'false' : 'true');
    });
    dots.forEach((dot, n) => {
      dot.classList.toggle('is-active', n === index);
      dot.setAttribute('aria-selected', n === index ? 'true' : 'false');
    });
    const active = slides[index];
    if (caption && active) {
      caption.textContent = active.getAttribute('data-caption') || '';
    }
  };

  prev?.addEventListener('click', () => show(index - 1));
  next?.addEventListener('click', () => show(index + 1));
  dots.forEach((dot, n) => dot.addEventListener('click', () => show(n)));

  root.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowLeft') show(index - 1);
    if (event.key === 'ArrowRight') show(index + 1);
  });

  let timer = setInterval(() => show(index + 1), 6000);
  root.addEventListener('mouseenter', () => clearInterval(timer));
  root.addEventListener('mouseleave', () => {
    timer = setInterval(() => show(index + 1), 6000);
  });

  show(index);
})();
