// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { remarkDocLinks } from './src/remark-doc-links.mjs';

// https://astro.build/config
export default defineConfig({
	// GitHub Pages serves project sites from https://<user>.github.io/<repo>/
	site: 'https://symonxdd.github.io',
	base: '/rivus',
	markdown: {
		remarkPlugins: [remarkDocLinks],
	},
	integrations: [
		starlight({
			title: 'Rivus',
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/symonxdd/rivus' },
			],
			sidebar: [
				{ label: 'Overview', link: '/' },
				{ label: 'Architecture', link: '/architecture/' },
			],
		}),
	],
});
