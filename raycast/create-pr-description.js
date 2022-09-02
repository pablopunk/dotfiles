const url = process.argv[2];

const parts = url.split('/');

let prTitle = parts[parts.length - 1].split('-').join(' ');
prTitle = prTitle[0].toUpperCase() + prTitle.slice(1);

const branchName = (
  parts[parts.length - 2] +
  '-' +
  parts[parts.length - 1]
).slice(0, 20);

const elysiumUrl =
  'https://' + branchName.toLowerCase() + '-app.testingmazeco.cloud/';

const body = `
[${parts[parts.length - 2]}]: ${prTitle}
### What this PR does

1.
2.

### Human readable changelog

[Edit Live Maze] ${prTitle} ([${parts[parts.length - 2]}](${url}))

### How to test it

#### Flow 1

[Loom]()
[Elysium](${elysiumUrl})

- [ ] 
- [ ] 
- [ ] 

### Potential risk for production

Low

### Checklist:

- [x] I have performed a self-review of my own code
- [ ] I have reviewed the design changes with a product designer (with screenshot(s), Loom, gif or preview link).  
No UI changes
- [x] I have tested locally that my solution works.  
- [ ] I have tested in elysium that my solution works.  
- [x] I have added tests that prove my fix is effective or that my feature works.  
- [x] I have attached screenshot(s), Loom link or gif showing my work in action.  
`;

process.stdout.write(body.trim());
