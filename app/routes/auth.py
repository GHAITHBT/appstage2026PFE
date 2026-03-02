from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
from app.models import db, User, Zone
from datetime import datetime

auth_bp = Blueprint('auth', __name__)

def login_required(f):
    """Decorator to check if user is logged in"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please log in first.', 'warning')
            return redirect(url_for('auth.login'))
        return f(*args, **kwargs)
    return decorated_function

def role_required(*roles):
    """Decorator to check user role"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'user_id' not in session:
                flash('Please log in first.', 'warning')
                return redirect(url_for('auth.login'))
            
            user = User.query.get(session['user_id'])
            if not user or user.role not in roles:
                flash('You do not have permission to access this page.', 'danger')
                return redirect(url_for('main.dashboard'))
            return f(*args, **kwargs)
        return decorated_function
    return decorator

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        user = User.query.filter_by(username=username).first()
        
        # Check password: either hashed match OR direct plain password match
        if user and (check_password_hash(user.password, password) or password == user.password):
            if not user.is_active:
                flash('Your account has been deactivated.', 'danger')
                return redirect(url_for('auth.login'))
            
            session['user_id'] = user.id
            session['username'] = user.username
            session['role'] = user.role
            session['full_name'] = user.full_name
            session.permanent = True
            
            flash(f'Welcome back, {user.first_name}!', 'success')
            return redirect(url_for('main.dashboard'))
        else:
            flash('Invalid username or password.', 'danger')
    
    return render_template('auth/login.html')

@auth_bp.route('/logout')
def logout():
    session.clear()
    flash('You have been logged out.', 'info')
    return redirect(url_for('auth.login'))

@auth_bp.route('/register', methods=['GET', 'POST'])
@role_required('admin')
def register():
    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        role = request.form.get('role', 'technician')
        department = request.form.get('department')
        
        if password != confirm_password:
            flash('Passwords do not match.', 'danger')
            return redirect(url_for('auth.register'))
        
        if User.query.filter_by(username=username).first():
            flash('Username already exists.', 'danger')
            return redirect(url_for('auth.register'))
        
        if User.query.filter_by(email=email).first():
            flash('Email already exists.', 'danger')
            return redirect(url_for('auth.register'))
        
        supervisor_id = request.form.get('supervisor_id')
        supervisor_id = int(supervisor_id) if supervisor_id else None
        
        user = User(
            username=username,
            password=generate_password_hash(password),
            email=email,
            first_name=first_name,
            last_name=last_name,
            role=role,
            department=department,
            zone=request.form.get('zone'),
            supervisor_id=supervisor_id,
            is_active=True
        )
        
        db.session.add(user)
        db.session.commit()
        
        flash(f'User {username} created successfully!', 'success')
        return redirect(url_for('auth.register'))
    
    # GET request - show form with available zones and supervisors
    zones = Zone.query.all()
    supervisors = User.query.filter(User.role.in_(['supervisor', 'admin'])).order_by(User.first_name, User.last_name).all()
    return render_template('auth/register.html', zones=zones, supervisors=supervisors)

@auth_bp.route('/profile')
@login_required
def profile():
    user = User.query.get(session['user_id'])
    zones = Zone.query.all()
    return render_template('auth/profile.html', user=user, zones=zones)

@auth_bp.route('/profile/update', methods=['POST'])
@login_required
def update_profile():
    user = User.query.get(session['user_id'])
    
    user.email = request.form.get('email', user.email)
    user.first_name = request.form.get('first_name', user.first_name)
    user.last_name = request.form.get('last_name', user.last_name)
    user.department = request.form.get('department', user.department)
    user.zone = request.form.get('zone', user.zone)
    
    new_password = request.form.get('new_password')
    if new_password:
        current_password = request.form.get('current_password')
        if not check_password_hash(user.password, current_password):
            flash('Current password is incorrect.', 'danger')
            return redirect(url_for('auth.profile'))
        user.password = generate_password_hash(new_password)
    
    db.session.commit()
    flash('Profile updated successfully!', 'success')
    return redirect(url_for('auth.profile'))

@auth_bp.route('/users')
@login_required
@role_required('admin')
def list_users():
    """List all users with edit/delete options"""
    page = request.args.get('page', 1, type=int)
    search = request.args.get('search', '')
    role_filter = request.args.get('role', '')
    
    query = User.query
    
    if search:
        query = query.filter(
            (User.username.ilike(f'%{search}%')) |
            (User.first_name.ilike(f'%{search}%')) |
            (User.last_name.ilike(f'%{search}%')) |
            (User.email.ilike(f'%{search}%'))
        )
    
    if role_filter:
        query = query.filter_by(role=role_filter)
    
    users = query.order_by(User.created_at.desc()).paginate(page=page, per_page=20)
    
    return render_template(
        'auth/users_list.html',
        users=users,
        search=search,
        role_filter=role_filter
    )

@auth_bp.route('/users/<int:user_id>/edit', methods=['GET', 'POST'])
@login_required
@role_required('admin')
def edit_user(user_id):
    """Edit user details"""
    user = User.query.get_or_404(user_id)
    
    if request.method == 'POST':
        user.first_name = request.form.get('first_name', user.first_name)
        user.last_name = request.form.get('last_name', user.last_name)
        user.email = request.form.get('email', user.email)
        user.role = request.form.get('role', user.role)
        user.department = request.form.get('department', user.department)
        user.zone = request.form.get('zone', user.zone)
        user.is_active = request.form.get('is_active') == 'on'
        
        supervisor_id = request.form.get('supervisor_id')
        user.supervisor_id = int(supervisor_id) if supervisor_id else None
        
        db.session.commit()
        flash(f'User {user.username} updated successfully!', 'success')
        return redirect(url_for('auth.list_users'))
    
    zones = Zone.query.all()
    supervisors = User.query.filter(User.role.in_(['supervisor', 'admin']), User.id != user_id).order_by(User.first_name, User.last_name).all()
    
    return render_template(
        'auth/edit_user.html',
        user=user,
        zones=zones,
        supervisors=supervisors
    )

@auth_bp.route('/users/<int:user_id>/reset-password', methods=['GET', 'POST'])
@login_required
@role_required('admin')
def reset_user_password(user_id):
    """Reset user password"""
    user = User.query.get_or_404(user_id)
    
    if request.method == 'POST':
        new_password = request.form.get('new_password')
        confirm_password = request.form.get('confirm_password')
        
        if not new_password or not confirm_password:
            flash('Password fields are required.', 'danger')
            return redirect(url_for('auth.reset_user_password', user_id=user_id))
        
        if new_password != confirm_password:
            flash('Passwords do not match.', 'danger')
            return redirect(url_for('auth.reset_user_password', user_id=user_id))
        
        if len(new_password) < 6:
            flash('Password must be at least 6 characters long.', 'danger')
            return redirect(url_for('auth.reset_user_password', user_id=user_id))
        
        user.password = generate_password_hash(new_password)
        db.session.commit()
        
        flash(f'Password for user {user.username} has been reset successfully!', 'success')
        return redirect(url_for('auth.list_users'))
    
    return render_template('auth/reset_password.html', user=user)

@auth_bp.route('/users/<int:user_id>/toggle', methods=['POST'])
@login_required
@role_required('admin')
def toggle_user_status(user_id):
    """Toggle user active status"""
    user = User.query.get_or_404(user_id)
    user.is_active = not user.is_active
    db.session.commit()
    
    status = 'activated' if user.is_active else 'deactivated'
    flash(f'User {user.username} has been {status}.', 'success')
    return redirect(url_for('auth.list_users'))

@auth_bp.route('/users/<int:user_id>/delete', methods=['POST'])
@login_required
@role_required('admin')
def delete_user(user_id):
    """Delete user"""
    user = User.query.get_or_404(user_id)
    username = user.username
    
    db.session.delete(user)
    db.session.commit()
    
    flash(f'User {username} has been deleted successfully!', 'success')
    return redirect(url_for('auth.list_users'))

    db.session.commit()
    session['full_name'] = user.full_name
    flash('Profile updated successfully!', 'success')
    return redirect(url_for('auth.profile'))
