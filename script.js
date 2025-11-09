// Resume Builder JavaScript Functions

// Add new skill category
function addSkillCategory() {
    const container = document.getElementById('skillsContainer');
    const newCategory = document.createElement('div');
    newCategory.className = 'skill-category';
    newCategory.innerHTML = `
        <h4 contenteditable="true">New Skill Category</h4>
        <div class="skills-list">
            <span class="skill-tag" contenteditable="true">Skill 1</span>
            <span class="skill-tag" contenteditable="true">Skill 2</span>
        </div>
        <button class="remove-btn" onclick="removeElement(this.parentElement)">Remove</button>
    `;
    container.appendChild(newCategory);
}

// Add new experience
function addExperience() {
    const container = document.getElementById('experienceContainer');
    const newExperience = document.createElement('div');
    newExperience.className = 'experience-item';
    newExperience.innerHTML = `
        <div class="experience-header">
            <h4 contenteditable="true">Job Title</h4>
            <span class="company" contenteditable="true">Company Name</span>
            <span class="duration" contenteditable="true">Start Date - End Date</span>
        </div>
        <ul class="achievements">
            <li contenteditable="true">Key achievement or responsibility #1</li>
            <li contenteditable="true">Key achievement or responsibility #2</li>
        </ul>
        <button class="remove-btn" onclick="removeElement(this.parentElement)">Remove</button>
    `;
    container.appendChild(newExperience);
}

// Add new certification
function addCertification() {
    const container = document.getElementById('certificationsContainer');
    const newCert = document.createElement('div');
    newCert.className = 'cert-item';
    newCert.innerHTML = `
        <div class="cert-info">
            <h4 contenteditable="true">Certification Name</h4>
            <span class="cert-issuer" contenteditable="true">Issuing Organization</span>
            <span class="cert-date" contenteditable="true">Year</span>
        </div>
        <a href="#" class="cert-link" contenteditable="true">View Certificate</a>
        <button class="remove-btn" onclick="removeElement(this.parentElement)">Remove</button>
    `;
    container.appendChild(newCert);
}

// Add new education
function addEducation() {
    const container = document.getElementById('educationContainer');
    const newEducation = document.createElement('div');
    newEducation.className = 'education-item';
    newEducation.innerHTML = `
        <h4 contenteditable="true">Degree Name</h4>
        <span class="institution" contenteditable="true">University Name</span>
        <span class="graduation-year" contenteditable="true">Year</span>
        <button class="remove-btn" onclick="removeElement(this.parentElement)">Remove</button>
    `;
    container.appendChild(newEducation);
}

// Add new project
function addProject() {
    const container = document.getElementById('projectsContainer');
    const newProject = document.createElement('div');
    newProject.className = 'project-item';
    newProject.innerHTML = `
        <h4 contenteditable="true">Project Name</h4>
        <p class="project-description" contenteditable="true">Brief description of the project, technologies used, and your role.</p>
        <div class="project-links">
            <a href="#" contenteditable="true">Live Demo</a>
            <a href="#" contenteditable="true">GitHub</a>
        </div>
        <button class="remove-btn" onclick="removeElement(this.parentElement)">Remove</button>
    `;
    container.appendChild(newProject);
}

// Remove element
function removeElement(element) {
    if (confirm('Are you sure you want to remove this item?')) {
        element.remove();
    }
}

// Save resume data to localStorage
function saveResume() {
    const resumeData = {
        name: document.getElementById('name').textContent,
        jobTitle: document.getElementById('jobTitle').textContent,
        location: document.getElementById('location').textContent,
        email: document.getElementById('email').textContent,
        phone: document.getElementById('phone').textContent,
        linkedin: document.getElementById('linkedin').textContent,
        github: document.getElementById('github').textContent,
        summary: document.getElementById('summary').textContent,
        timestamp: new Date().toISOString()
    };
    
    localStorage.setItem('resumeData', JSON.stringify(resumeData));
    
    // Show success message
    const saveBtn = document.querySelector('.save-btn');
    const originalText = saveBtn.textContent;
    saveBtn.textContent = '✅ Saved!';
    saveBtn.style.background = '#27ae60';
    
    setTimeout(() => {
        saveBtn.textContent = originalText;
        saveBtn.style.background = '#3498db';
    }, 2000);
}

// Load resume data from localStorage
function loadResume() {
    const savedData = localStorage.getItem('resumeData');
    if (savedData) {
        const resumeData = JSON.parse(savedData);
        
        document.getElementById('name').textContent = resumeData.name || 'Your Full Name';
        document.getElementById('jobTitle').textContent = resumeData.jobTitle || 'Your Job Title';
        document.getElementById('location').textContent = resumeData.location || 'City, Country';
        document.getElementById('email').textContent = resumeData.email || 'your.email@example.com';
        document.getElementById('phone').textContent = resumeData.phone || '+1 (555) 123-4567';
        document.getElementById('linkedin').textContent = resumeData.linkedin || 'linkedin.com/in/yourprofile';
        document.getElementById('github').textContent = resumeData.github || 'github.com/yourusername';
        document.getElementById('summary').textContent = resumeData.summary || 'Write a compelling professional summary here...';
        document.getElementById('footerName').textContent = resumeData.name || 'Your Name';
    }
}

// Print resume
function printResume() {
    // Hide edit controls before printing
    const editControls = document.querySelectorAll('.add-btn, .remove-btn, .edit-controls');
    editControls.forEach(control => {
        control.style.display = 'none';
    });
    
    // Print the page
    window.print();
    
    // Show edit controls after printing
    setTimeout(() => {
        editControls.forEach(control => {
            control.style.display = '';
        });
    }, 1000);
}

// Handle profile photo upload
function handlePhotoUpload() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    
    input.onchange = function(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = function(e) {
                document.getElementById('profilePhoto').src = e.target.result;
                localStorage.setItem('profilePhoto', e.target.result);
            };
            reader.readAsDataURL(file);
        }
    };
    
    input.click();
}

// Auto-save functionality
function setupAutoSave() {
    const editableElements = document.querySelectorAll('[contenteditable="true"]');
    editableElements.forEach(element => {
        element.addEventListener('blur', saveResume);
    });
}

// Initialize the resume builder
document.addEventListener('DOMContentLoaded', function() {
    loadResume();
    setupAutoSave();
    
    // Load saved profile photo
    const savedPhoto = localStorage.getItem('profilePhoto');
    if (savedPhoto) {
        document.getElementById('profilePhoto').src = savedPhoto;
    }
    
    // Add click handler for profile photo
    document.getElementById('profilePhoto').addEventListener('click', handlePhotoUpload);
    
    // Add keyboard shortcuts
    document.addEventListener('keydown', function(e) {
        if (e.ctrlKey || e.metaKey) {
            switch(e.key) {
                case 's':
                    e.preventDefault();
                    saveResume();
                    break;
                case 'p':
                    e.preventDefault();
                    printResume();
                    break;
            }
        }
    });
});

// Export resume data as JSON
function exportResume() {
    const resumeData = {
        personalInfo: {
            name: document.getElementById('name').textContent,
            jobTitle: document.getElementById('jobTitle').textContent,
            location: document.getElementById('location').textContent,
            email: document.getElementById('email').textContent,
            phone: document.getElementById('phone').textContent,
            linkedin: document.getElementById('linkedin').textContent,
            github: document.getElementById('github').textContent
        },
        summary: document.getElementById('summary').textContent,
        skills: Array.from(document.querySelectorAll('.skill-category')).map(cat => ({
            category: cat.querySelector('h4').textContent,
            skills: Array.from(cat.querySelectorAll('.skill-tag')).map(skill => skill.textContent)
        })),
        experience: Array.from(document.querySelectorAll('.experience-item')).map(exp => ({
            title: exp.querySelector('h4').textContent,
            company: exp.querySelector('.company').textContent,
            duration: exp.querySelector('.duration').textContent,
            achievements: Array.from(exp.querySelectorAll('.achievements li')).map(li => li.textContent)
        })),
        certifications: Array.from(document.querySelectorAll('.cert-item')).map(cert => ({
            name: cert.querySelector('h4').textContent,
            issuer: cert.querySelector('.cert-issuer').textContent,
            date: cert.querySelector('.cert-date').textContent,
            link: cert.querySelector('.cert-link').textContent
        })),
        education: Array.from(document.querySelectorAll('.education-item')).map(edu => ({
            degree: edu.querySelector('h4').textContent,
            institution: edu.querySelector('.institution').textContent,
            year: edu.querySelector('.graduation-year').textContent
        })),
        projects: Array.from(document.querySelectorAll('.project-item')).map(proj => ({
            name: proj.querySelector('h4').textContent,
            description: proj.querySelector('.project-description').textContent,
            links: Array.from(proj.querySelectorAll('.project-links a')).map(link => ({
                text: link.textContent,
                url: link.href
            }))
        })),
        exportDate: new Date().toISOString()
    };
    
    const dataStr = JSON.stringify(resumeData, null, 2);
    const dataBlob = new Blob([dataStr], {type: 'application/json'});
    const url = URL.createObjectURL(dataBlob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = 'resume-data.json';
    link.click();
    
    URL.revokeObjectURL(url);
}
