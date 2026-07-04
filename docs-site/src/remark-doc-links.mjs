import { visit } from 'unist-util-visit';
import path from 'node:path';

// /docs/*.md files link to each other using plain relative filenames
// (e.g. "architecture.md") so those links work when browsing the repo on
// GitHub. Starlight pages don't live at those URLs though (README.md is
// "/", architecture.md is "/architecture/", etc.), so this rewrites those
// links to the matching Starlight route at build time.
const slugFor = (filename) => (filename === 'README.md' ? '' : filename.replace(/\.md$/, ''));

export function remarkDocLinks() {
	return (tree, file) => {
		const currentFile = path.basename(file.history[0] ?? file.path ?? '');
		const currentSlug = slugFor(currentFile);

		visit(tree, 'link', (node) => {
			const match = node.url.match(/^([\w-]+\.md)$/);
			if (!match) return;

			const targetSlug = slugFor(match[1]);

			if (currentSlug === '') {
				node.url = targetSlug === '' ? './' : `${targetSlug}/`;
			} else {
				node.url = targetSlug === '' ? '../' : `../${targetSlug}/`;
			}
		});
	};
}
